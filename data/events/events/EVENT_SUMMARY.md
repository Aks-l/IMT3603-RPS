# Event Collection Summary

## 11 Diverse Events Created

All events are organized in `data/events/events/` with each event in its own folder containing all options.

### Event List

| ID | Event Name | Options | Balance | Weight |
|----|------------|---------|---------|--------|
| 10 | **Ancient Shrine** | 3 | Healing (free or paid) | 1.0 |
| 11 | **Mysterious Chest** | 3 | Risk/reward with custom script | 1.0 |
| 12 | **Traveling Gambler** | 3 | High risk gambling (custom script) | 0.9 |
| 13 | **Injured Traveler** | 3 | Moral choice (help/rob/ignore) | 1.1 |
| 14 | **Street Performer** | 4 | Tipping system (4 options) | 0.7 |
| 15 | **Suspicious Trader** | 4 | Scam/haggle/combat/leave | 1.0 |
| 16 | **Abandoned Campfire** | 3 | Rest or loot abandoned camp | 0.9 |
| 17 | **Fork in the Road** | 3 | Path choice (safe/risky/middle) | 1.0 |
| 18 | **Mysterious Merchant** | 4 | Potion buying (price tiers) | 0.8 |
| 19 | **Training Grounds** | 4 | Training choices (safe/risky/combat) | 0.7 |
| 20 | **Suspicious Goods** | 3 | Post-combat loot (CHAINED from 15) | 0.0 |

### Design Features

**Balance & Risk/Reward:**
- Low risk, low reward: Shrine (free pray = +2 HP)
- Medium risk, medium reward: Traveler (help = +40 gold, rob = +35 gold -1 HP)
- High risk, high reward: Gambler (50 gold bet = 150 gold or lose all)
- Risk with guaranteed reward: Fork right path (+50 gold + combat)

**Player Agency:**
- Every event has a "leave/decline/ignore" option
- Multiple meaningful choices (3-4 options per event)
- No "trap" choices - all options have purpose

**Variety:**
- Healing events: Shrine, Campfire, Mysterious Merchant, Training
- Gold events: Gambler, Chest, Traveler, Fork, Trader
- Combat events: Trader (if accuse), Fork (right path), Training (mock combat)
- Moral choices: Injured Traveler (help/rob/ignore)
- Scams: Suspicious Trader (buy = waste, haggle = good deal)
- **Event Chaining: Suspicious Trader → Combat → Suspicious Goods (ID 15 → 20)**

**Custom Scripts:**
- Mysterious Chest: Uses MysteryBoxScript for random rewards
- Traveling Gambler: Uses GambleScript with configurable bets (30g or 50g)

**Event Chaining:**
- Suspicious Trader "Accuse" option: triggers_combat=true AND next_event_id=20
- After defeating the trader, chains to "Suspicious Goods" event (loot decision)
- Demonstrates: Combat → Event chaining pattern

**Event Weights:**
- Common (1.0-1.2): Shrine, Chest, Traveler, Trader, Fork
- Uncommon (0.7-0.9): Gambler, Campfire, Performer, Training, Mysterious Merchant

### Folder Structure
```
data/events/events/
├── shrine/
│   ├── event.tres
│   ├── option_pray.tres
│   ├── option_offer.tres
│   └── option_leave.tres
├── mysterious_chest/
│   ├── event.tres
│   ├── option_open.tres (uses custom script)
│   ├── option_examine.tres
│   └── option_leave.tres
├── traveling_gambler/
│   ├── event.tres
│   ├── option_bet30.tres (uses custom script)
│   ├── option_bet50.tres (uses custom script)
│   └── option_decline.tres
├── injured_traveler/
│   ├── event.tres
│   ├── option_help.tres
│   ├── option_rob.tres
│   └── option_ignore.tres
├── street_performer/
│   ├── event.tres
│   ├── option_tip5.tres
│   ├── option_tip20.tres
│   ├── option_watch.tres
│   └── option_move.tres
├── suspicious_trader/
│   ├── event.tres
│   ├── option_buy.tres (scam!)
│   ├── option_haggle.tres (good deal!)
│   ├── option_accuse.tres (combat)
│   └── option_walk.tres
├── abandoned_campfire/
│   ├── event.tres
│   ├── option_rest.tres
│   ├── option_search.tres
│   └── option_leave.tres
├── fork_in_road/
│   ├── event.tres
│   ├── option_left.tres (safe)
│   ├── option_right.tres (risky + combat)
│   └── option_middle.tres (bushwhack)
├── mysterious_merchant/
│   ├── event.tres
│   ├── option_buy_expensive.tres (60g = +5 HP)
│   ├── option_buy_cheap.tres (15g = +1 HP)
│   ├── option_ask_free.tres (+1 HP free)
│   └── option_decline.tres
└── training_dummy/
    ├── event.tres
    ├── option_train.tres (+2 HP)
    ├── option_intense.tres (+bonus -1 HP)
    ├── option_test.tres (combat + 20g)
    └── option_skip.tres
└── trader_reward/
    ├── event.tres (ID 20, chained from Suspicious Trader)
    ├── option_take_loot.tres (75g -2 HP)
    ├── option_take_modest.tres (50g fair)
    └── option_leave_all.tres (0g +1 HP)
```

### Balance Summary

**Gold Balance:**
- Ways to gain gold: 15-50 gold from safe choices
- Ways to lose gold: 5-60 gold for services/bets
- Risk/reward: Gambler can win 90-150g or lose 30-50g

**Health Balance:**
- Free healing: +1 to +3 HP (Shrine pray, Campfire rest, Training)
- Paid healing: +1 to +5 HP for 15-60 gold
- Health loss: -1 HP for greedy/risky choices (rob, bushwhack, intense train)

**Combat Triggers:**
- Optional combat: Trader (accuse), Training (test), Fork (right path)
- All combat options give rewards (gold or pre-combat treasure)

### Player Experience Goals

1. **Always have agency**: Can always decline/leave
2. **Risk is transparent**: "risky" options clearly labeled
3. **Rewards scale with risk**: Bigger risks = bigger rewards
4. **No gotchas**: Even "bad" choices have some logic
5. **Variety**: Different event types for replay value
6. **Balanced**: No event is strictly better than others
