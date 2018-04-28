# SafeTrade

###### Scary warning: Most of these addons were made long ago during Feenix days, then a lot was changed/added to prepare for Corecraft. Since it died, they still haven't been extensively tested on modern servers.

### [Downloads](https://github.com/Shanghi/SafeTrade/releases)

***

## Purpose:
This will attempt to protect against trade scams where someone removes or changes money or items right before you accept.

## Using:
1. If you trade anything to an untrusted person, the Trade button will be replaced with a Lock button. Once both of you set up the items and money, click Lock to go into locked mode.

2. While in locked mode, you can inspect the items and click Trade without worrying about any changes. If they do change something, the Trade button will be disabled and you'll have to click a Confirm button to continue back to locked mode. If you make a change, then it will go back to unlocked mode.

| Commands | Description |
| --- | --- |
| /safetrade trust [name] | _toggle [name] as a trusted player - leave off [name] to list them_ |
| /safetrade&nbsp;trustguild&nbsp;\<"on"\|"off"> | _if on, trust all guild members_ |
| /safetrade&nbsp;alwayslock&nbsp;\<"on"\|"off"> | _if on, always use the Lock system even if you aren't offering any items/money yourself_ |

## Screenshots / Example:
![!](https://i.imgur.com/vouNYVA.jpg)

1. You meet a stranger to set up a fair deal as shown above. After both sides set up their offers, click the "Lock" button.
2. In locked mode, make sure everything looks OK then click Trade to complete the deal.
3. The scoundrel sneakily removed some gold right before trading and hopes you won't notice! The Trade button is now disabled - click "Confirm change" to go back into locked mode.

## Limitations:
* When your item is enchanted, it counts as you making a change. When their item is enchanted, it counts as them making a change.