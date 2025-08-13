# Transportation Option Selection Feature

## Overview

This feature allows users to select different transportation options (Bike, Cab Economy, Auto, Cab Premium) and highlights the selected option in the UI.

## Implementation Details

### MapController Changes

The `MapController` class has been enhanced with the following features:

1. **State Management**:

   - `_selectedTransportOption`: Tracks the currently selected option (default: 'car_economy')
   - `_availableRideOptions`: Stores the list of available ride options

2. **New Methods**:

   - `selectTransportOption(String optionId)`: Selects a transportation option and updates the UI
   - `getSelectedTransportOptionDetails()`: Returns details of the currently selected option
   - `selectedTransportOption` getter: Returns the ID of the selected option
   - `availableRideOptions` getter: Returns the list of available options

3. **Updated Methods**:
   - `getRideOptions()`: Now uses the selection state to mark the correct option as selected

### UI Changes

The map home page has been updated with:

1. **Interactive Option Cards**:

   - Each transportation option is now tappable
   - Selected options are highlighted with:
     - Black border (2px) instead of grey (1px)
     - Light background tint for better visibility
     - Darker icon background

2. **Dynamic Book Button**:
   - Shows the name of the currently selected option in the booking confirmation

## Transportation Options Available

1. **Bike** 🏍️

   - Fastest option for short distances
   - Most economical choice
   - Shows "FASTEST" badge when applicable

2. **Cab Economy** 🚕 (Default Selection)

   - Affordable car rides
   - Shows passenger capacity badge (👥 4)
   - Moderate pricing

3. **Auto** 🛺

   - Three-wheeler auto-rickshaw
   - Good for medium distances in traffic
   - Mid-range pricing

4. **Cab Premium** 🚗
   - Premium car service
   - Highest price point
   - Enhanced comfort

## Usage

1. **Selecting an Option**:

   - User taps on any transportation option card
   - The selected option gets highlighted immediately
   - Previous selection is automatically deselected

2. **Visual Feedback**:

   - Selected option has a black border and tinted background
   - Non-selected options have grey borders
   - Icons have different background colors based on selection state

3. **Booking**:
   - Book button shows "Booking [Selected Option]..." when pressed
   - Default shows "Booking Cab Economy..." if no selection is made

## Technical Notes

- Uses `notifyListeners()` to update the UI when selection changes
- `setState()` is called in the UI to trigger rebuilds
- Option IDs are used for internal tracking:
  - 'bike' for Bike
  - 'car_economy' for Cab Economy
  - 'auto' for Auto
  - 'car_premium' for Cab Premium

## Integration

The feature integrates seamlessly with the existing ride booking flow and maintains the current pricing and route calculation logic for each transportation mode.
