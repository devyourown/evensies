package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.money.Money
import org.springframework.stereotype.Component
import tools.jackson.databind.JsonNode
import tools.jackson.databind.node.ObjectNode
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeParseException
import java.util.UUID
import kotlin.math.abs

/**
 * Rejects a push batch before anything is stored. Validates each event against the state after the previous ones
 * and returns the batch to store: a `payment.created` with `status: "sent"` whose receiver is a placeholder or the
 * sender themselves is rewritten to `"confirmed"`, and an expense carrying `payers` gets `paidBy` = the primary payer
 * (applier rule 10), and an `attachment.deleted` gets the `expenseId` its receipt is on (dropped for an unknown id), so
 * every client pulls the same payload and the expense History filter finds it. Phase 8: an expense's `recurrenceId` naming
 * a series this group doesn't have is dropped together with `occurrence` (an offline client can't know its series was
 * rejected). A null actor is Evensies (the repeat scheduler): it may post `occurrence` >= 1.
 * [paymentCreator] returns the user id that created an already-stored payment; [uploaded] whether an attachment id was
 * uploaded to this group (Phase 7, `POST /groups/{id}/attachments/{attachmentId}`).
 */
@Component
class EventValidator {
    fun validateAll(
        initial: GroupState, actorUserId: UUID?, events: List<IncomingEvent>, paymentCreator: (String) -> String? = { null },
        uploaded: (String) -> Boolean = { false },
    ): List<IncomingEvent> {
        var state = initial
        val createdHere = HashSet<String>()
        return events.map { raw ->
            val e = normalize(state, actorUserId, raw)
            validate(state, actorUserId, e, uploaded) { id -> if (id in createdHere) actorUserId?.toString() else paymentCreator(id) }
            if (e.type == "payment.created") createdHere += e.payload.text("paymentId")!!
            state = EventApplier.apply(state, e.type, e.payload)
            e
        }
    }

    private fun normalize(s: GroupState, actor: UUID?, e: IncomingEvent): IncomingEvent {
        if (!e.payload.isObject) return e
        return when (e.type) {
            "expense.created" -> withPrimaryPayer(withKnownSeries(s, e) { it }) { it }
            "expense.updated" -> withPrimaryPayer(withKnownSeries(s, e) { it.get("fields") as? ObjectNode }) { it.get("fields")?.takeIf(JsonNode::isObject) }
            "payment.created" -> {
                if (e.payload.text("status") != "sent") return e
                val receiverUser = s.members[e.payload.text("toMember")]?.userId
                if (receiverUser != null && receiverUser != actor?.toString()) return e
                e.copy(payload = (e.payload.deepCopy() as ObjectNode).put("status", "confirmed"))
            }
            "attachment.deleted" -> {
                // The expense the receipt is on, so the History filter (payload->>'expenseId') finds the removal.
                val on = s.attachments[e.payload.text("attachmentId")]?.expenseId
                val sent = e.payload.get("expenseId")
                if (on == null && sent == null) return e
                if (on != null && sent?.isString == true && sent.asString() == on) return e
                val copy = e.payload.deepCopy() as ObjectNode
                if (on == null) copy.remove("expenseId") else copy.put("expenseId", on)
                e.copy(payload = copy)
            }
            else -> e
        }
    }

    /**
     * Phase 8: drops `recurrenceId` and `occurrence` from the object [at] picks when `recurrenceId` is a string naming no
     * series of this group (stopped ones count), so the expense is stored without a series instead of a 400.
     */
    private fun withKnownSeries(s: GroupState, e: IncomingEvent, at: (JsonNode) -> JsonNode?): IncomingEvent {
        val id = at(e.payload)?.field("recurrenceId")?.takeIf { it.isString }?.asString() ?: return e
        if (id in s.recurrences) return e
        val copy = e.payload.deepCopy() as ObjectNode
        (at(copy) as ObjectNode).remove(listOf("recurrenceId", "occurrence"))
        return e.copy(payload = copy)
    }

    /**
     * Rewrites (or adds) `paidBy` in the object [at] picks (the payload or `fields`) to the primary payer when it carries
     * well-formed, non-empty `payers`. Anything malformed is left for [validate] to reject.
     */
    private fun withPrimaryPayer(e: IncomingEvent, at: (JsonNode) -> JsonNode?): IncomingEvent {
        val target = at(e.payload) ?: return e
        val payers = target.field("payers")?.takeIf { isShareList(it) && !it.isEmpty }?.let { target.shares("payers") } ?: return e
        if (target.field("paidBy")?.isString == false) return e
        val primary = EventApplier.primaryPayer(payers)!!
        if (target.text("paidBy") == primary) return e
        val copy = e.payload.deepCopy() as ObjectNode
        (at(copy) as ObjectNode).put("paidBy", primary)
        return e.copy(payload = copy)
    }

    private fun validate(s: GroupState, actor: UUID?, e: IncomingEvent, uploaded: (String) -> Boolean, paymentCreator: (String) -> String?) {
        val p = e.payload
        if (!p.isObject) bad("payload must be an object")
        when (e.type) {
            "group.created" -> { requireText(p, "name", MAX_GROUP_NAME); requireCurrency(p.text("defaultCurrency")); requireGroupType(p) }
            "group.updated" -> {
                if (p.has("kind")) bad("kind is set when the group is created and cannot change") // rule 13
                if (p.has("name")) requireText(p, "name", MAX_GROUP_NAME)
                // Rule 12 ignores a late currency change instead of rejecting it: an offline client can't know.
                if (p.field("defaultCurrency") != null) requireCurrency(p.text("defaultCurrency"))
                if (p.has("simplifyDebts") && !p.get("simplifyDebts").isBoolean) bad("simplifyDebts must be true or false")
                p.field("defaultSplit")?.let { validateDefaultSplit(s, it) }
                requireGroupType(p)
                // A non-null id comes from PUT /groups/{id}/cover only (EventService.pushAsMember refuses it from clients).
                if (p.field("coverImageId") != null) requireUuid(p, "coverImageId")
            }
            "group.deleted", "group.restored" -> Unit // any active member; the payload's keys are not read (rule 17)
            "member.added" -> {
                requireUuid(p, "memberId"); requireText(p, "name", MAX_MEMBER_NAME); requireOwnUser(p, actor)
                if (p.text("memberId") !in s.members) {
                    if (s.kind == "friend" && s.members.size >= 2) throw ApiException.limit("A friend group has exactly two members")
                    if (s.members.size >= MAX_MEMBERS) throw ApiException.limit("A group can have at most $MAX_MEMBERS members")
                    if (p.text("userId") != null) requireNoActiveMember(s, actor)
                }
            }
            "member.linked" -> {
                requireMember(s, p.text("memberId")); requireUuid(p, "userId"); requireOwnUser(p, actor)
                if (s.members.getValue(p.text("memberId")!!).userId != null) {
                    throw ApiException.badRequest("MEMBER_TAKEN", "That member is already linked to a user")
                }
                requireNoActiveMember(s, actor)
            }
            "member.removed" -> {
                if (s.kind == "friend") bad("Nobody can leave or be removed from a friend group")
                requireMember(s, p.text("memberId"))
            }
            "expense.created" -> {
                requireUuid(p, "expenseId"); requireExpenseFields(p, created = true); requireNoDeleted(p); requireSeriesFields(p, created = true, actor)
                validateExpense(s, EventApplier.apply(s, e.type, p).expenses.getValue(p.text("expenseId")!!))
            }
            "expense.updated" -> {
                requireUuid(p, "expenseId")
                val f = p.get("fields")
                if (f == null || !f.isObject) bad("fields must be an object")
                requireExpenseFields(f, created = false); requireSeriesFields(f, created = false, actor)
                val before = s.expenses[p.text("expenseId")]
                if (before != null && !before.deleted) {
                    validateExpense(s, EventApplier.apply(s, e.type, p).expenses.getValue(before.id))
                }
            }
            "expense.deleted" -> {
                requireUuid(p, "expenseId")
                // Phase 6 move: only the shape is checked, the target group and expense are not looked up.
                p.field("movedTo")?.let { if (!it.isObject) bad("movedTo must be an object or null"); requireUuid(it, "groupId"); requireUuid(it, "expenseId") }
            }
            "expense.restored" -> requireUuid(p, "expenseId")
            "comment.added" -> {
                requireUuid(p, "commentId"); requireNoDeleted(p)
                // Exactly one target (Phase 6: a payment); null counts as absent.
                val onExpense = p.field("expenseId") != null
                if (onExpense == (p.field("paymentId") != null)) bad("Send exactly one of expenseId and paymentId")
                requireUuid(p, if (onExpense) "expenseId" else "paymentId")
                val author = s.members[p.text("authorMemberId")]
                if (author == null || author.removed || !isActor(author.userId, actor)) {
                    throw ApiException.forbidden("authorMemberId must be your own member")
                }
                if (onExpense && p.text("expenseId") !in s.expenses) bad("expenseId refers to an unknown expense")
                if (!onExpense && p.text("paymentId") !in s.payments) bad("paymentId refers to an unknown payment")
                val text = p.field("text")?.takeIf { it.isString }?.asString()
                if (text.isNullOrBlank() || text.length > MAX_COMMENT) bad("text must be 1 to $MAX_COMMENT characters")
                try { Instant.parse(p.text("createdAt") ?: bad("createdAt is required")) } catch (_: DateTimeParseException) {
                    bad("createdAt must be an ISO-8601 instant")
                }
            }
            "comment.deleted" -> {
                requireUuid(p, "commentId")
                val comment = s.comments[p.text("commentId")] ?: return // rule 4: ignored by the applier
                if (!isActor(s.members[comment.authorMemberId]?.userId, actor)) {
                    throw ApiException.forbidden("Only the author can delete a comment")
                }
            }
            "payment.created" -> {
                requireUuid(p, "paymentId"); requireNoDeleted(p)
                requireMember(s, p.text("fromMember")); requireMember(s, p.text("toMember"))
                if (p.text("fromMember") == p.text("toMember")) bad("fromMember and toMember must differ")
                requireAmount(p.field("amount")?.takeIf(::isMinorUnits)?.asLong()); requireCurrency(p.text("currency")); requireDate(p.text("date"))
                p.text("status")?.let { if (it != "sent" && it != "confirmed") bad("status must be sent or confirmed") }
            }
            "payment.confirmed" -> {
                requireUuid(p, "paymentId")
                val payment = s.payments[p.text("paymentId")] ?: bad("paymentId refers to an unknown payment")
                if (!isActor(s.members[payment.toMember]?.userId, actor)) {
                    throw ApiException.forbidden("Only the receiver can confirm a payment")
                }
            }
            "payment.deleted", "payment.restored" -> {
                requireUuid(p, "paymentId")
                // Phase 7 edit marker: only the shape is checked, the new payment is not looked up.
                if (p.field("replacedBy") != null && e.type == "payment.deleted") requireUuid(p, "replacedBy")
                val payment = s.payments[p.text("paymentId")] ?: return // rule 4: ignored by the applier
                val allowed = isActor(paymentCreator(payment.id), actor) ||
                    isActor(s.members[payment.fromMember]?.userId, actor) || isActor(s.members[payment.toMember]?.userId, actor)
                if (!allowed) throw ApiException.forbidden("Only the payer or the receiver can delete or restore a payment")
            }
            "attachment.added" -> {
                requireUuid(p, "attachmentId"); requireUuid(p, "expenseId")
                val id = p.text("attachmentId")!!
                val expenseId = p.text("expenseId")!!
                s.attachments[id]?.let { if (it.expenseId == expenseId) return else bad("This receipt is on another expense") }
                if (!uploaded(id)) throw ApiException.badRequest("ATTACHMENT_NOT_UPLOADED", "Upload the photo to this group first")
                if (expenseId !in s.expenses) bad("expenseId refers to an unknown expense")
                if (s.attachments.values.count { it.expenseId == expenseId && !it.deleted } >= MAX_RECEIPTS) {
                    throw ApiException.limit("An expense can have at most $MAX_RECEIPTS receipts")
                }
            }
            "attachment.deleted" -> requireUuid(p, "attachmentId") // an unknown id is ignored (rule 4); expenseId is normalized
            "recurrence.created" -> {
                requireUuid(p, "recurrenceId")
                if (p.field("frequency")?.takeIf { it.isString }?.asString() !in FREQUENCIES) bad("frequency must be one of ${FREQUENCIES.joinToString()}")
                val startDate = p.field("startDate")?.takeIf { it.isString }?.asString()
                requireDate(startDate)
                val zone = p.field("timeZone")?.takeIf { it.isString }?.asString()
                if (zone == null || zone.length !in 1..MAX_TIME_ZONE || runCatching { ZoneId.of(zone) }.isFailure) {
                    bad("timeZone must be a time zone name or offset of at most $MAX_TIME_ZONE characters")
                }
                val template = p.field("template")
                if (template == null || !template.isObject) bad("template must be an object")
                requireNoScheduleKeys(template, "template")
                validateTemplate(s, actor, template, startDate!!, uploaded)
                requireRemindDays(p)
                if (p.text("recurrenceId") !in s.recurrences && s.recurrences.values.count { !it.deleted } >= MAX_RECURRENCES) {
                    throw ApiException.limit("A group can have at most $MAX_RECURRENCES repeating expenses")
                }
            }
            "recurrence.updated" -> {
                requireUuid(p, "recurrenceId")
                requireRemindDays(p)
                // Rule 18: remindDaysBefore is a sibling of fields; fields stays required (`{}` for a reminder change alone).
                val f = p.get("fields")
                if (f == null || !f.isObject) bad("fields must be an object")
                requireNoScheduleKeys(f, "fields")
                requireExpenseFields(f, created = false)
                // Rule 15: an unknown or stopped series ignores the update, so only its types are checked.
                val r = s.recurrences[p.text("recurrenceId")]?.takeUnless { it.deleted } ?: return
                validateTemplate(s, actor, EventApplier.apply(s, e.type, p).recurrences.getValue(r.id).template, r.startDate, uploaded)
            }
            "recurrence.deleted" -> requireUuid(p, "recurrenceId") // an unknown or stopped series is ignored (rules 4, 15)
            else -> throw ApiException.badRequest("UNKNOWN_TYPE", "Unknown event type ${e.type}")
        }
    }

    /** Rule 17: a present `type` is one of [GROUP_TYPES] (null too is rejected: it would read as "keep"). */
    private fun requireGroupType(p: JsonNode) {
        if (p.has("type") && p.get("type").let { !it.isString || it.asString() !in GROUP_TYPES }) bad("type must be one of ${GROUP_TYPES.joinToString()}")
    }

    /** Rule 18: a present `remindDaysBefore` is an integer 1–7 or null. */
    private fun requireRemindDays(p: JsonNode) {
        val n = p.field("remindDaysBefore") ?: return
        if (!n.isIntegralNumber || !n.canConvertToInt() || n.asInt() !in 1..7) bad("remindDaysBefore must be an integer from 1 to 7 or null")
    }

    /** Template keys a repeat or the schedule sets; a template or `recurrence.updated.fields` never carries them. */
    private fun requireNoScheduleKeys(node: JsonNode, name: String) {
        SCHEDULE_KEYS.firstOrNull { node.has(it) }?.let { bad("$name cannot contain $it") }
    }

    /** A template must pass as the first repeat would: `expense.created` with a new id on the start date (the expense codes). */
    private fun validateTemplate(s: GroupState, actor: UUID?, template: JsonNode, startDate: String, uploaded: (String) -> Boolean) {
        val payload = (template.deepCopy() as ObjectNode).put("expenseId", UUID.randomUUID().toString()).put("date", startDate)
        validate(s, actor, IncomingEvent(UUID.randomUUID(), "expense.created", payload, Instant.EPOCH), uploaded) { null }
    }

    /**
     * Phase 8 series fields of `expense.created` or `expense.updated.fields` (after [withKnownSeries]): both set or both
     * null (missing = null in a create; an update sends both keys or neither); `occurrence` from 0, and only 0 from a
     * user: later repeats are added by Evensies (null [actor]) alone.
     */
    private fun requireSeriesFields(node: JsonNode, created: Boolean, actor: UUID?) {
        if (!created && node.has("recurrenceId") != node.has("occurrence")) bad("Send recurrenceId and occurrence together")
        val n = node.field("occurrence")
        if ((node.field("recurrenceId") == null) != (n == null)) bad("recurrenceId and occurrence are both set or both null")
        if (n == null) return
        requireUuid(node, "recurrenceId")
        if (!isMinorUnits(n) || n.asLong() !in 0..Int.MAX_VALUE.toLong()) bad("occurrence must be an integer from 0 to ${Int.MAX_VALUE}")
        if (actor != null && n.asLong() != 0L) bad("Only the first expense of a series can be added by a member (occurrence 0)")
    }

    private fun validateExpense(s: GroupState, e: ExpenseDto) {
        if (e.description.isBlank()) bad("description is required")
        requireAmount(e.amount); requireCurrency(e.currency); requireDate(e.date)
        requireMember(s, e.paidBy)
        if (e.fxRateToDefault != null && e.fxRateToDefault < 0) bad("fxRateToDefault must be >= 0")
        // Payers before shares: an amount-only edit of a multi-payer expense (rule 10d) breaks both, the payers explain it.
        val payers = HashSet<String>()
        for (p in e.payers) {
            requireMember(s, p.memberId); requireAmount(p.amount)
            if (!payers.add(p.memberId)) bad("duplicate payer ${p.memberId}")
        }
        if (e.payers.sumOf { it.amount } != e.amount) {
            throw ApiException.badRequest("PAYERS_SUM_MISMATCH", "Payers sum to ${e.payers.sumOf { it.amount }} but amount is ${e.amount}")
        }
        e.split?.field("input")?.propertyNames()?.forEach { requireMember(s, it) }
        if (e.split?.text("mode") == "itemized") {
            e.split.field("bill")?.field("lines")?.values()?.forEach { line -> line.field("memberIds")?.values()?.forEach { requireMember(s, it.asString()) } }
        }
        val seen = HashSet<String>()
        for (sh in e.shares) {
            requireMember(s, sh.memberId); requireAmount(sh.amount)
            if (!seen.add(sh.memberId)) bad("duplicate share for member ${sh.memberId}")
        }
        if (e.shares.sumOf { it.amount } != e.amount) {
            throw ApiException.badRequest("SUM_MISMATCH", "Shares sum to ${e.shares.sumOf { it.amount }} but amount is ${e.amount}")
        }
    }

    /**
     * Raw JSON types of the expense keys present in `expense.created` or `expense.updated.fields` (docs/API.md 적용
     * 규칙 9). The Kotlin readers coerce a wrong type (a number becomes a string, a string amount null) while the Dart
     * applier casts and throws, so such an event would stop sync on every app. `null` passes here: it is ignored or
     * clears the value in an update, and [validateExpense] rejects it where a created expense needs a value — except
     * `amount` and `shares`, which the readers would default and so must be present in `expense.created`.
     */
    private fun requireExpenseFields(node: JsonNode, created: Boolean) {
        for (k in listOf("description", "currency", "paidBy", "date", "category", "notes")) {
            if (node.field(k)?.isString == false) bad("$k must be a string")
        }
        node.field("description")?.let { if (it.asString().length > MAX_DESCRIPTION) bad("description must be at most $MAX_DESCRIPTION characters") }
        node.field("notes")?.let { if (it.asString().length > MAX_NOTES) bad("notes must be a string of at most $MAX_NOTES characters") }
        node.field("amount")?.let { if (!isMinorUnits(it)) bad("amount must be an integer") }
        // `1e999` reads as Infinity, which passes isNumber but is stored as the string "Infinity".
        node.field("fxRateToDefault")?.let { if (!it.isNumber || !it.asDouble().isFinite()) bad("fxRateToDefault must be a finite number or null") }
        node.field("shares")?.let { if (!isShareList(it)) bad("shares must be an array of {memberId: string, amount: integer}") }
        node.field("payers")?.let {
            if (!isShareList(it) || it.isEmpty) bad("payers must be a non-empty array of {memberId: string, amount: integer}")
        }
        node.field("refund")?.let { if (!it.isBoolean) bad("refund must be true or false") }
        node.field("split")?.let { requireSplitSpec(it, "split", EXPENSE_SPLIT_MODES) }
        if (created && node.field("amount") == null) bad("amount is required")
        if (created && node.field("shares") == null) bad("shares is required")
    }

    private fun isMinorUnits(n: JsonNode) = n.isIntegralNumber && n.canConvertToLong()

    private fun isShareList(n: JsonNode) =
        n.isArray && n.values().all { it.isObject && it.field("memberId")?.isString == true && it.field("amount")?.let(::isMinorUnits) == true }

    /**
     * SplitSpec shape (docs/API.md "SplitSpec"): `{mode, input?, bill?}`, other keys kept as sent. `input` values are
     * finite numbers: percent and share counts >= 0, adjustments whole by value (Dart's jsonEncode sends `1000.0`).
     * `itemized` (Phase 7) has a `bill` instead; its member ids are checked on the applied expense ([validateExpense]).
     */
    private fun requireSplitSpec(spec: JsonNode, name: String, modes: Set<String>) {
        if (!spec.isObject) bad("$name must be an object or null")
        val mode = spec.field("mode")?.takeIf { it.isString }?.asString()
        if (mode !in modes) bad("$name.mode must be one of ${modes.joinToString()}")
        val input = spec.field("input")
        if (mode == "equal" || mode == "itemized") {
            if (input != null) bad("$name.input is not used with $mode")
            if (mode == "itemized") requireBill(spec.field("bill"), "$name.bill")
            return
        }
        if (input == null || !input.isObject) bad("$name.input must be an object for $mode")
        for (v in input.values()) {
            val d = v.takeIf { it.isNumber }?.asDouble()
            if (d == null || !d.isFinite()) bad("$name.input values must be finite numbers")
            if (mode == "adjustment") {
                if (d != Math.rint(d)) bad("adjustments must be whole minor units")
            } else if (d < 0) {
                bad("$name.input values must be >= 0")
            }
        }
    }

    /** ItemizedBill shape (docs/API.md "SplitSpec"): 1–200 lines, amounts 0..[MAX_AMOUNT]; missing or null tax/tip/discount = 0. */
    private fun requireBill(bill: JsonNode?, name: String) {
        fun minor(n: JsonNode?) = n != null && isMinorUnits(n) && n.asLong() in 0..MAX_AMOUNT
        if (bill == null || !bill.isObject) bad("$name must be an object")
        val lines = bill.field("lines")
        if (lines == null || !lines.isArray || lines.size() !in 1..MAX_BILL_LINES) bad("$name.lines must have 1 to $MAX_BILL_LINES entries")
        for (line in lines.values()) {
            if (!line.isObject) bad("$name.lines entries must be objects")
            val itemName = line.field("name")?.takeIf { it.isString }?.asString()?.trim()
            if (itemName == null || itemName.length !in 1..MAX_ITEM_NAME) bad("$name.lines[].name must be 1 to $MAX_ITEM_NAME characters")
            if (!minor(line.field("amount"))) bad("$name.lines[].amount must be an integer from 0 to $MAX_AMOUNT")
            val ids = line.field("memberIds")
            if (ids == null || !ids.isArray || ids.isEmpty || !ids.values().all { it.isString }) bad("$name.lines[].memberIds must be a non-empty array of member ids")
            if (ids.values().map { it.asString() }.toSet().size != ids.size()) bad("$name.lines[].memberIds has a member twice")
        }
        for (k in listOf("tax", "tip", "discount")) {
            bill.field(k)?.let { if (!minor(it)) bad("$name.$k must be an integer from 0 to $MAX_AMOUNT") }
        }
    }

    private fun validateDefaultSplit(s: GroupState, spec: JsonNode) {
        requireSplitSpec(spec, "defaultSplit", DEFAULT_SPLIT_MODES)
        val input = spec.get("input")
        input.propertyNames().forEach { requireMember(s, it) }
        val total = input.values().sumOf { it.asDouble() }
        when (spec.get("mode").asString()) {
            "percent" -> if (abs(total - 100.0) >= 0.001) throw ApiException.badRequest("SUM_MISMATCH", "defaultSplit percents sum to $total, not 100")
            "shares" -> if (total == 0.0) bad("defaultSplit shares must not all be 0")
        }
    }

    /** The Dart applier builds created rows with `fromJson({...payload})`, which would honour a `deleted` key; Kotlin ignores it. */
    private fun requireNoDeleted(p: JsonNode) {
        val d = p.field("deleted") ?: return
        if (!d.isBoolean || d.asBoolean()) bad("deleted cannot be set when creating")
    }

    /** One active member per user: a second one (or re-linking someone else's) would let a user act as another member. */
    private fun requireNoActiveMember(s: GroupState, actor: UUID?) {
        if (s.members.values.any { isActor(it.userId, actor) && !it.removed }) {
            throw ApiException.badRequest("MEMBER_TAKEN", "You already have a member in this group")
        }
    }

    private fun requireMember(s: GroupState, id: String?) {
        if (id == null || id !in s.members) throw ApiException.badRequest("UNKNOWN_MEMBER", "Member $id is not in this group")
    }

    /** Clients may only link a member to themselves. */
    private fun requireOwnUser(p: JsonNode, actor: UUID?) {
        val userId = p.text("userId") ?: return
        if (!isActor(userId, actor)) throw ApiException.forbidden("userId must be your own user id")
    }

    /** [userId] is the pushing user; never true for Evensies (null [actor]) or a placeholder (null [userId]). */
    private fun isActor(userId: String?, actor: UUID?) = actor != null && userId == actor.toString()

    /** A non-blank JSON string (no coercion from numbers: the Dart applier casts) of at most [max] UTF-16 units. */
    private fun requireText(p: JsonNode, k: String, max: Int = Int.MAX_VALUE) {
        val v = p.field(k)?.takeIf { it.isString }?.asString()
        if (v.isNullOrBlank() || v.length > max) bad("$k must be a non-blank string" + if (max < Int.MAX_VALUE) " of at most $max characters" else "")
    }

    /**
     * Canonical lowercase form only (what the app and `UUID.toString` make): state keys are the raw strings while the
     * tables parse them, so `"AAAA…"` or `"1-1-1-1-1"` would miss an existing entity in the state yet overwrite its row.
     */
    private fun requireUuid(p: JsonNode, k: String) {
        val v = p.text(k) ?: bad("$k is required")
        val canonical = try { UUID.fromString(v).toString() } catch (_: IllegalArgumentException) { null }
        if (canonical != v) bad("$k must be a lowercase UUID")
    }

    /**
     * 0..[MAX_AMOUNT]: with at most [MAX_MEMBERS] distinct payers or shares a sum stays far below Long.MAX_VALUE, so
     * `Σ payers == amount` can't pass by wrapping around.
     */
    private fun requireAmount(amount: Long?) {
        if (amount == null) bad("amount must be an integer")
        if (amount < 0) throw ApiException.badRequest("NEGATIVE_AMOUNT", "Amounts must be >= 0")
        if (amount > MAX_AMOUNT) bad("Amounts must be at most $MAX_AMOUNT minor units")
    }

    private fun requireCurrency(c: String?) {
        if (c == null || !Money.isKnown(c)) throw ApiException.badRequest("UNKNOWN_CURRENCY", "Unknown currency $c")
    }

    /** LocalDate.parse alone also takes "+10000-01-01"; clients read the month as date[0..7]. */
    private fun requireDate(d: String?) {
        if (d == null) bad("date is required")
        if (d.length != 10) bad("date must be YYYY-MM-DD")
        try { LocalDate.parse(d) } catch (_: DateTimeParseException) { bad("date must be YYYY-MM-DD") }
    }

    private fun bad(message: String): Nothing = throw ApiException.badRequest("VALIDATION", message)

    companion object {
        const val MAX_MEMBERS = 50
        const val MAX_DESCRIPTION = 200
        const val MAX_NOTES = 500
        const val MAX_COMMENT = 1000
        const val MAX_GROUP_NAME = 100
        const val MAX_MEMBER_NAME = 100
        const val MAX_AMOUNT = 10_000_000_000_000L
        const val MAX_BILL_LINES = 200
        const val MAX_ITEM_NAME = 100
        /** Abuse cap: live receipts per expense (409). */
        const val MAX_RECEIPTS = 10
        /** Abuse cap: series per group that aren't stopped (409). */
        const val MAX_RECURRENCES = 100
        const val MAX_TIME_ZONE = 64
        val FREQUENCIES = setOf("weekly", "biweekly", "monthly", "yearly")
        val GROUP_TYPES = setOf("trip", "home", "couple", "other")
        val SCHEDULE_KEYS = listOf("expenseId", "date", "recurrenceId", "occurrence", "frequency", "startDate", "timeZone")
        val EXPENSE_SPLIT_MODES = setOf("equal", "percent", "shares", "adjustment", "itemized")
        val DEFAULT_SPLIT_MODES = setOf("percent", "shares")
    }
}
