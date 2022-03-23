# Live Text Implementation
References: iOS Photos, Telegram

### State Semantics
In both photos and Telegram, the Live Text overlay is stateful.
Users can activate the overlay, swipe to another photo, swipe back, and the overlay is still present.
However, if the cell is removed from memory, the state is reset.

Pro: if a user swipes back and forth between 2 cells, the overlay remains
Con: confusing state semantics, not all users realize cells are ejected from memory

I think the pro is overstated. 
Cells is kicked out after 2 cells on Photos (iPhone XR, iOS 15.3), 
and most likely the user is switching to another *app*, not another *photo*.

Therefore, for Hyperthread we will disable the overlay when the user begins swiping.
This process will be visible, making the semantics clear 
(as opposed to disabling the overlay when the cell finishes going off screen). 
