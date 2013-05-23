# glass-nest

### Description

This is an exploration of the Google Glass [Mirror API](https://developers.google.com/glass/overview) and the unofficial [nest](http://nest.com) access, to control your nest thermostat from a glass unit, using voice commands.


### Usage flow

#### On Website

1. Authenticate by visiting /login
2. Enter nest credentials

#### On Glass Unit

A card will now appear in your timeline. Pin this card.

##### To set/change temperature

1. Navigate to pinned card
2. Tap into menu
3. Select `Reply`
4. Any reply with the prases, "temperature to XX" or "XX degrees" will be interpreted and the target temperature set.

##### To update card

In order to preserve battery ( and due to the unofficial nature of the nest API ) your temperature card is not updated automaticall in regular intervals ( this may be changed later )

1. Navigate to pinned card
2. Tap into menu
3. Select `Update`

Updated card will be sent to the glass unit