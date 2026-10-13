#!/usr/bin/env python3
"""Seed made-up demo data for store screenshots into a LOCAL Evensies server (dev login on).

Usage: python3 seed.py http://localhost:18201
Everything goes through the HTTP API (docs/API.md): /auth/dev, /me, /groups, /invites/{code}/join, /friends,
/me/payment-methods and POST /groups/{id}/events. Splits are computed with the app's rules (domain/split.dart,
domain/itemized.dart) so the editor reopens them in the same mode.
"""
import json, sys, time, uuid, urllib.request, urllib.error

BASE = sys.argv[1].rstrip('/') if len(sys.argv) > 1 else 'http://localhost:18201'


def call(method, path, body=None, token=None, retried=False):
    req = urllib.request.Request(BASE + path, method=method,
                                 data=None if body is None else json.dumps(body).encode(),
                                 headers={'Content-Type': 'application/json',
                                          **({'Authorization': 'Bearer ' + token} if token else {})})
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        if e.code == 429 and not retried:  # invite endpoints allow 10 per minute per IP
            time.sleep(61)
            return call(method, path, body, token, True)
        sys.exit(f'{method} {path} -> {e.code} {e.read().decode()}')


def uid():
    return str(uuid.uuid4())


# --- splits, ported from app/lib/domain/split.dart and itemized.dart ---
def equal(amount, members):
    s = sorted(members)
    r = {m: amount // len(s) for m in s}
    for m in s[:amount % len(s)]:
        r[m] += 1
    return r


def shares_split(amount, counts):
    s = sorted(counts)
    w = {m: round(counts[m] * 100) for m in s}
    W = sum(w.values())
    r = {m: amount * w[m] // W for m in s}
    left = amount - sum(r.values())
    for m in [m for m in s if w[m] > 0][:left]:
        r[m] += 1
    return r


def itemized(bill):
    sums = {}
    for l in bill['lines']:
        people = tuple(sorted(set(l['memberIds'])))
        sums[people] = sums.get(people, 0) + l['amount']
    sub = {}
    for people, amt in sums.items():
        for m, v in equal(amt, list(people)).items():
            sub[m] = sub.get(m, 0) + v
    S = sum(l['amount'] for l in bill['lines'])
    net = bill['tax'] + bill['tip'] - bill['discount']
    ids = sorted(sub)
    extra = {m: abs(net) * sub[m] // S for m in ids}
    left = abs(net) - sum(extra.values())
    for m in ids:
        if left == 0:
            break
        if sub[m] > 0:
            extra[m] += 1
            left -= 1
    return {m: sub[m] + extra[m] if net >= 0 else sub[m] - extra[m] for m in ids}, S + net


# --- people ---
NAMES = ['Alex', 'Maya', 'Jonas', 'Priya', 'Leo']
U = {}
for n in NAMES:
    a = call('POST', '/auth/dev', {'name': n})
    U[n] = {'token': a['accessToken'], 'id': a['user']['id']}
    call('PATCH', '/me', {'displayName': n, 'homeCurrency': 'EUR', 'language': 'en'}, U[n]['token'])

# Ways to get paid (fake handles), so Settle up shows pay buttons when Alex owes Maya.
call('PUT', '/me/payment-methods', [{'type': 'paypal', 'value': 'maya.demo'},
                                    {'type': 'wise', 'value': 'https://wise.com/pay/me/mayademo'}], U['Maya']['token'])
call('PUT', '/me/payment-methods', [{'type': 'revolut', 'value': 'jonasdemo'}], U['Jonas']['token'])


# Everything below is scheduled and then run in time order, so the server's feed order (feedId) matches the dates.
# After seeding, README.txt's SQL sets each event's received_at to its createdAt (the feed shows received_at).
ACTIONS = []


def at(t, fn):
    ACTIONS.append((t, len(ACTIONS), fn))


def plan_group(name, gtype, owner, others):
    """Ids now (payloads need them), creation + joins later at the group's time."""
    gid, M = uid(), {n: uid() for n in [owner, *others]}

    def create():
        call('POST', '/groups', {'id': gid, 'name': name, 'defaultCurrency': 'EUR', 'memberId': M[owner],
                                 'memberName': owner, 'type': gtype}, U[owner]['token'])
        code = call('GET', f'/groups/{gid}', token=U[owner]['token'])['inviteCode']
        for o in others:
            call('POST', f'/invites/{code}/join', {'newMemberId': M[o], 'name': o}, U[o]['token'])
    return gid, M, create


def push(gid, who, events):
    body = [{'clientId': uid(), 'type': t, 'payload': p, 'createdAt': ts} for t, p, ts in events]
    return call('POST', f'/groups/{gid}/events', body, U[who]['token'])


def ev(t, gid, who, type_, payload):
    at(t, lambda: push(gid, who, [(type_, payload, t)]))


def expense(M, desc, amount, date, category, payers, shares, split, notes=None, rec=None):
    """payers / shares: {name: minor units}. Returns (expenseId, payload)."""
    eid = uid()
    p = {'expenseId': eid, 'description': desc, 'amount': amount, 'currency': 'EUR', 'fxRateToDefault': None,
         'paidBy': M[max(payers, key=payers.get)],
         'payers': [{'memberId': M[n], 'amount': a} for n, a in payers.items()],
         'refund': False, 'split': split, 'date': date, 'category': category, 'notes': notes,
         'shares': [{'memberId': M[n], 'amount': a} for n, a in shares.items()],
         'recurrenceId': rec, 'occurrence': 0 if rec else None}
    assert sum(payers.values()) == amount and sum(shares.values()) == amount, desc
    return eid, p


def by_name(M, split_by_id):
    inv = {v: k for k, v in M.items()}
    return {inv[m]: a for m, a in split_by_id.items()}


def eq(M, amount, names):
    return by_name(M, equal(amount, [M[n] for n in names]))


def simple(t, gid, M, who, desc, amt, date, cat, among):
    """One payer, split equally between [among]."""
    eid, p = expense(M, desc, amt, date, cat, {who: amt}, eq(M, amt, among), {'mode': 'equal'})
    ev(t, gid, who, 'expense.created', p)
    return eid


def payment(t, gid, M, who, frm, to, amt, date, status='confirmed'):
    pid = uid()
    ev(t, gid, who, 'payment.created', {'paymentId': pid, 'fromMember': M[frm], 'toMember': M[to], 'amount': amt,
                                         'currency': 'EUR', 'date': date, 'status': status})
    return pid


def comment(t, gid, M, who, eid, text):
    ev(t, gid, who, 'comment.added', {'commentId': uid(), 'expenseId': eid, 'authorMemberId': M[who], 'text': text,
                                      'createdAt': t})


# --- Berlin weekend (Alex is owed) ---
ber, B, create = plan_group('Berlin weekend', 'trip', 'Alex', ['Jonas', 'Priya'])
BL = ['Alex', 'Jonas', 'Priya']
at('2026-09-12T12:00:00Z', create)
simple('2026-09-12T14:00:00Z', ber, B, 'Alex', 'Airbnb in Kreuzberg', 26400, '2026-09-12', 'transportation.hotel', BL)
simple('2026-09-12T20:30:00Z', ber, B, 'Jonas', 'Currywurst and beers', 4170, '2026-09-12', 'food.dining_out', BL)
simple('2026-09-13T09:00:00Z', ber, B, 'Priya', 'U-Bahn day tickets', 2970, '2026-09-13', 'transportation.bus_train', BL)
payment('2026-09-20T18:00:00Z', ber, B, 'Alex', 'Priya', 'Alex', 5800, '2026-09-20')

# --- Climbing crew (settled up) ---
clb, C, create = plan_group('Climbing crew', 'other', 'Alex', ['Jonas', 'Leo'])
at('2026-09-27T15:00:00Z', create)
simple('2026-09-27T17:00:00Z', clb, C, 'Leo', 'Bouldering day passes', 4500, '2026-09-27', 'entertainment.sports',
       ['Alex', 'Jonas', 'Leo'])
for n in ['Alex', 'Jonas']:
    pid = payment('2026-09-28T10:00:00Z', clb, C, n, n, 'Leo', 1500, '2026-09-28', status='sent')
    ev('2026-09-28T12:00:00Z', clb, 'Leo', 'payment.confirmed', {'paymentId': pid})

# --- Flat 3B (home, monthly rent repeats) ---
flat, F, create = plan_group('Flat 3B', 'home', 'Alex', ['Maya', 'Leo'])
FL = ['Alex', 'Maya', 'Leo']
at('2026-10-01T06:00:00Z', create)
rec = uid()
_, p_rent = expense(F, 'Rent', 165000, '2026-10-01', 'home.rent', {'Alex': 165000}, eq(F, 165000, FL),
                    {'mode': 'equal'}, rec=rec)
template = {k: v for k, v in p_rent.items() if k not in ('expenseId', 'date', 'recurrenceId', 'occurrence')}
at('2026-10-01T08:00:00Z', lambda: push(flat, 'Alex', [
    ('recurrence.created', {'recurrenceId': rec, 'frequency': 'monthly', 'startDate': '2026-10-01',
                            'timeZone': '+01:00', 'template': template}, '2026-10-01T08:00:00Z'),
    ('expense.created', p_rent, '2026-10-01T08:00:00Z')]))
simple('2026-10-04T18:00:00Z', flat, F, 'Maya', 'Electricity (September)', 8460, '2026-10-04', 'utilities.electricity', FL)
simple('2026-10-05T12:00:00Z', flat, F, 'Leo', 'Fibre internet', 3999, '2026-10-05', 'utilities.tv_phone_internet', FL)
payment('2026-10-06T20:00:00Z', flat, F, 'Alex', 'Maya', 'Alex', 50000, '2026-10-06')
simple('2026-10-09T19:30:00Z', flat, F, 'Leo', 'Groceries at Continente', 6320, '2026-10-09', 'food.groceries', FL)
simple('2026-10-11T10:00:00Z', flat, F, 'Maya', 'Cleaning supplies', 1875, '2026-10-11', 'home.household_supplies', FL)

# --- Lisbon trip (the main group: itemized, multi-payer, shares, a settled payment, comments) ---
lis, L, create = plan_group('Lisbon trip', 'trip', 'Alex', ['Maya', 'Jonas', 'Priya', 'Leo'])
ALL = NAMES
at('2026-10-02T13:00:00Z', create)
hotel = simple('2026-10-02T15:10:00Z', lis, L, 'Maya', 'Hotel in Alfama, 4 nights', 64000, '2026-10-02',
               'transportation.hotel', ALL)
comment('2026-10-02T15:30:00Z', lis, L, 'Jonas', hotel, 'Thanks for booking, Maya!')
simple('2026-10-02T17:40:00Z', lis, L, 'Leo', 'Taxi from the airport', 3240, '2026-10-02', 'transportation.taxi',
       ['Alex', 'Maya', 'Leo'])
_, p = expense(L, 'Dinner at Time Out Market', 11450, '2026-10-02', 'food.dining_out',
               {'Alex': 6000, 'Jonas': 5450}, eq(L, 11450, ALL), {'mode': 'equal'})  # two payers
ev('2026-10-02T21:30:00Z', lis, 'Alex', 'expense.created', p)
simple('2026-10-03T09:15:00Z', lis, L, 'Priya', 'Groceries at Pingo Doce', 4785, '2026-10-03', 'food.groceries', ALL)
simple('2026-10-03T11:05:00Z', lis, L, 'Alex', 'Tram 28 tickets', 1500, '2026-10-03', 'transportation.bus_train', ALL)
simple('2026-10-03T15:20:00Z', lis, L, 'Jonas', 'MAAT museum tickets', 6000, '2026-10-03', 'entertainment.other',
       ['Alex', 'Maya', 'Jonas', 'Priya'])
bill = {'lines': [
    {'name': 'Grilled octopus', 'amount': 2450, 'memberIds': [L['Alex']]},
    {'name': 'Bacalhau à Brás', 'amount': 2100, 'memberIds': [L['Maya']]},
    {'name': 'Sardines platter', 'amount': 3600, 'memberIds': [L['Jonas'], L['Priya']]},
    {'name': 'Clams in garlic', 'amount': 1950, 'memberIds': [L['Leo']]},
    {'name': 'Vinho Verde (2 bottles)', 'amount': 3200, 'memberIds': [L[n] for n in ALL]},
    {'name': 'Pastéis de nata', 'amount': 900, 'memberIds': [L[n] for n in ALL]},
], 'tax': 0, 'tip': 1400, 'discount': 0}
item_shares, item_total = itemized(bill)
seafood, p = expense(L, 'Seafood dinner in Cais do Sodré', item_total, '2026-10-04', 'food.dining_out',
                     {'Maya': item_total}, by_name(L, item_shares), {'mode': 'itemized', 'bill': bill})
ev('2026-10-04T22:10:00Z', lis, 'Maya', 'expense.created', p)
comment('2026-10-04T22:20:00Z', lis, L, 'Priya', seafood, 'Best sardines of my life 🐟')
comment('2026-10-04T22:25:00Z', lis, L, 'Alex', seafood, 'Split by item, so nobody pays for my octopus')
one = {L[n]: 1 for n in ALL}
_, p = expense(L, 'Train to Sintra', 2250, '2026-10-05', 'transportation.bus_train', {'Priya': 2250},
               by_name(L, shares_split(2250, one)), {'mode': 'shares', 'input': one})
ev('2026-10-05T08:40:00Z', lis, 'Priya', 'expense.created', p)
palace = {**one, L['Leo']: 2}  # Leo also paid for his sister
_, p = expense(L, 'Pena Palace tickets', 12000, '2026-10-05', 'entertainment.other', {'Alex': 12000},
               by_name(L, shares_split(12000, palace)), {'mode': 'shares', 'input': palace})
ev('2026-10-05T10:30:00Z', lis, 'Alex', 'expense.created', p)
payment('2026-10-07T19:00:00Z', lis, L, 'Maya', 'Leo', 'Maya', 15000, '2026-10-07')  # Leo settled up with Maya

# --- Friends: Alex & Priya, outside any group (needs a shared group, so after Lisbon/Berlin exist) ---
P = {}


def make_friend():
    fr = call('POST', '/friends', {'id': uid(), 'defaultCurrency': 'EUR', 'userId': U['Priya']['id']},
              U['Alex']['token'])
    snap = call('GET', f"/groups/{fr['id']}/snapshot", token=U['Alex']['token'])
    P['gid'] = fr['id']
    P.update({('Alex' if m['userId'] == U['Alex']['id'] else 'Priya'): m['id'] for m in snap['members']})


def friend_expense(t, who, desc, amt, date, cat):
    def run():
        M = {k: v for k, v in P.items() if k != 'gid'}
        _, p = expense(M, desc, amt, date, cat, {who: amt}, eq(M, amt, ['Alex', 'Priya']), {'mode': 'equal'})
        push(P['gid'], who, [('expense.created', p, t)])
    at(t, run)


at('2026-10-09T11:00:00Z', make_friend)
friend_expense('2026-10-09T13:00:00Z', 'Priya', 'Concert tickets', 9000, '2026-10-09', 'entertainment.music')
friend_expense('2026-10-12T11:30:00Z', 'Alex', 'Brunch', 3800, '2026-10-12', 'food.dining_out')

for _, _, fn in sorted(ACTIONS, key=lambda a: (a[0], a[1])):
    fn()

# --- balances check (same formula as docs/API.md "Balances") ---
for gid in [ber, clb, flat, lis, P['gid']]:
    s = call('GET', f'/groups/{gid}/snapshot', token=U['Alex']['token'])
    bal = {m['id']: 0 for m in s['members']}
    for e in s['expenses']:
        if e['deleted']:
            continue
        for x in e['payers']:
            bal[x['memberId']] += x['amount']
        for x in e['shares']:
            bal[x['memberId']] -= x['amount']
    for pm in s['payments']:
        if not pm['deleted']:
            bal[pm['fromMember']] += pm['amount']
            bal[pm['toMember']] -= pm['amount']
    names = {m['id']: m['name'] for m in s['members']}
    print(s['group']['name'], {names[m]: b / 100 for m, b in bal.items()})
