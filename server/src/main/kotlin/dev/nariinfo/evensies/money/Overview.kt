package dev.nariinfo.evensies.money

import dev.nariinfo.evensies.sync.GroupState

/**
 * One group's Settle up seen by a user (docs/API.md "Overview"). [personOf]: every member → person key (userId if linked;
 * "g:<groupId>" for a friend group's placeholder; "m:<memberId>" otherwise). [transfers]: [Balances.transfers].
 */
data class GroupLedger(val groupId: String, val personOf: Map<String, String>, val transfers: Map<String, List<Transfer>>) {
    companion object {
        /** null when no member is [myUserId]'s. */
        fun of(groupId: String, state: GroupState, myUserId: String): GroupLedger? {
            if (state.members.values.none { it.userId == myUserId }) return null
            val transfers = Balances.transfers(Balances.ofGroup(state), state.simplifyDebts)
            val personOf = state.members.values.associate { m ->
                m.id to (m.userId ?: if (state.kind == "friend") "g:$groupId" else "m:${m.id}")
            }
            return GroupLedger(groupId, personOf, transfers)
        }
    }
}

/** [people]: person → currency → amount (+ they owe me); [byGroup]: person → groupId → currency → amount. */
data class Overview(
    val people: Map<String, Map<String, Long>>,
    val byGroup: Map<String, Map<String, Map<String, Long>>>,
    val owedToMe: Map<String, Long>,
    val iOwe: Map<String, Long>,
) {
    companion object {
        /**
         * Every member of mine (removed ones included: a user who left and rejoined has two) is me. A transfer to me
         * adds to the sender, one from me subtracts from the receiver; between two of mine or two others it is ignored.
         * Summed per person and currency with no conversion; zeros, then empty persons and groups, are dropped.
         */
        fun compute(ledgers: List<GroupLedger>, myUserId: String): Overview {
            val byGroup = LinkedHashMap<String, LinkedHashMap<String, LinkedHashMap<String, Long>>>()
            for (l in ledgers) for ((cur, ts) in l.transfers) for (t in ts) {
                val a = l.personOf.getValue(t.from)
                val b = l.personOf.getValue(t.to)
                val (person, amount) = when {
                    b == myUserId && a != myUserId -> a to t.amount
                    a == myUserId && b != myUserId -> b to -t.amount
                    else -> continue
                }
                val cell = byGroup.getOrPut(person) { LinkedHashMap() }.getOrPut(l.groupId) { LinkedHashMap() }
                cell[cur] = (cell[cur] ?: 0L) + amount
            }
            val groups = byGroup.mapValues { (_, g) -> g.mapValues { (_, c) -> c.filterValues { it != 0L } }.filterValues { it.isNotEmpty() } }
                .filterValues { it.isNotEmpty() }
            val people = groups.mapValues { (_, g) ->
                g.values.flatMap { it.entries }.groupingBy { it.key }.fold(0L) { acc, e -> acc + e.value }.filterValues { it != 0L }
            }.filterValues { it.isNotEmpty() }
            fun total(sign: Long) = people.values.flatMap { it.entries }.filter { it.value * sign > 0 }
                .groupingBy { it.key }.fold(0L) { acc, e -> acc + e.value * sign }
            return Overview(people, groups, total(1), total(-1))
        }
    }
}
