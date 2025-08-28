# Downvote Functionality Implementation

## Overview
This implementation adds comprehensive downvote functionality to PartyAux, allowing users to downvote songs in the queue and current song, with automatic song removal when the downvote threshold is reached.

## Features Implemented

### 1. Enhanced Song Model
- Updated `Song.swift` to include downvote-related properties:
  - `downvotes: [String]` - Array of user emails who downvoted
  - `downvoteCount: Int` - Computed property for vote count
  - `hasUserDownvoted(_:)` - Method to check if user has voted

### 2. Room Manager Enhancements
- Added `maxDownvotes: Int` property to track room's downvote threshold
- Implemented `downvoteSong(songUuid:completion:)` method for API calls
- Enhanced socket event handlers:
  - `downvote` - Updates UI when someone downvotes
  - `delete_song_from_queue` - Handles automatic song removal
- Parses `max_downvotes` from room info API response

### 3. Queue View Updates
- **Downvote Threshold Indicator**: Creative animated component showing room's downvote limit
- **Enhanced Song Rows**: 
  - Shows current downvotes vs max (e.g., "2/5")
  - Circular progress indicator with color coding (gray → orange → red)
  - Visual warning when song approaches removal threshold
  - Prevents duplicate votes from same user
- **Real-time Updates**: Uses socket events to update vote counts instantly

### 4. Music Player View Updates
- **Current Song Downvoting**: Users can downvote the currently playing song
- **Downvote Status Display**: Progress bar showing current downvotes vs threshold
- **Visual Feedback**: 
  - Warning levels (info → warning → danger)
  - User vote indicator when they've already voted
  - Disabled state after voting
- **State Management**: Properly resets downvote state when songs change

### 5. Socket Integration
- **Real-time Sync**: All downvotes are immediately reflected across all clients
- **Automatic Removal**: Songs are removed automatically by backend when threshold reached
- **Queue Updates**: UI refreshes automatically when songs are removed or downvoted

## UI Components Added

### DownvoteThresholdIndicator
- Shows room's max downvote setting with animated icon
- Visual representation using circles
- Explains the threshold to users

### DownvoteProgressView
- Circular progress indicator for individual songs
- Color-coded warning system
- Shows "current/max" count

### CurrentSongDownvoteInfo
- Linear progress bar for current song
- Warning icons based on danger level
- User vote status indicator

## API Integration
- Uses `/add-downvote` endpoint with proper error handling
- Follows API documentation specifications
- Includes JWT authentication and room validation
- Provides user feedback on success/failure

## Creative Threshold Display
The downvote threshold is displayed creatively through:
1. **Animated header indicator** in queue view
2. **Color-coded progress bars** (gray → orange → red)
3. **Warning icons** that change based on danger level
4. **Visual feedback** with pulsing animations
5. **Circular progress** showing completion toward threshold

## Technical Details
- Prevents users from voting multiple times on same song
- Automatically refreshes data after vote actions
- Handles edge cases (no current song, network errors)
- Maintains state consistency across socket events
- Follows SwiftUI best practices for reactive UI updates

## Usage
1. Users see the downvote threshold displayed prominently in the queue
2. Each song shows its current downvote progress
3. Users can downvote songs they don't like (once per song)
4. Visual feedback indicates vote success and progress toward removal
5. Songs are automatically removed when threshold is reached
6. All clients see updates in real-time via socket events
