# Fitness Trail Explorer

A decentralized fitness trail management system built on the Stacks blockchain using Clarity smart contracts. Users can discover, rate, and track their completion of fitness trails in their area.

## Features

### Phase 1 ✅
- Add new fitness trails with name, location, and difficulty rating
- Retrieve trail information by ID
- Basic trail storage and management

### Phase 2 ✅
- **Fixed Bugs**: Proper trail ID generation and validation
- **Enhanced Security**: Input validation, access controls, and error handling
- **New Functionality**:
  - Trail rating system (1-5 stars)
  - Trail completion tracking with timing
  - User statistics and achievements
  - Trail deactivation by owners/creators
  - Average rating calculations

## Smart Contract Details

### Data Structures

**Trails Map**: Stores comprehensive trail information
- `id`: Unique trail identifier
- `name`: Trail name (max 64 characters)
- `location`: Location description (max 64 characters) 
- `difficulty`: Difficulty rating (1-5)
- `added-by`: Principal who added the trail
- `timestamp`: Block height when added
- `is-active`: Whether trail is active
- `total-ratings`: Number of user ratings
- `rating-sum`: Sum of all ratings for average calculation

**User Ratings**: Track individual user ratings per trail
**Trail Completions**: Record when users complete trails with timing
**User Statistics**: Aggregate user activity data

### Public Functions

#### Core Trail Management
- `add-trail(name, location, difficulty)` - Add a new trail
- `get-trail(id)` - Get basic trail information
- `get-trail-with-rating(id)` - Get trail with calculated average rating
- `deactivate-trail(id)` - Remove trail from active listings

#### User Interactions  
- `rate-trail(trail-id, rating)` - Rate a trail (1-5 stars)
- `complete-trail(trail-id, completion-time)` - Mark trail as completed
- `get-user-stats(user)` - Get user's activity statistics
- `get-user-trail-rating(trail-id, user)` - Check user's rating for a trail
- `get-trail-completion(trail-id, user)` - Get completion details

#### Utility Functions
- `get-trail-count()` - Get total number of trails
- `transfer-ownership(new-owner)` - Admin function for ownership transfer

### Security Features

- **Input Validation**: All difficulty and rating values must be 1-5
- **Access Control**: Only trail creators or contract owner can deactivate trails  
- **Error Handling**: Comprehensive error constants and validation
- **Duplicate Prevention**: Prevents duplicate trail IDs
- **Active Status**: Only active trails are visible in searches

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testnet/mainnet deployment

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd fitness-trail-explorer
```

2. Install dependencies and verify setup:
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

4. Start local development environment:
```bash
clarinet integrate
```

### Usage Examples

#### Adding a Trail
```clarity
(contract-call? .fitness-trail-explorer add-trail 
  "Mountain Peak Trail" 
  "Rocky Mountain National Park" 
  u4)
```

#### Rating a Trail
```clarity
(contract-call? .fitness-trail-explorer rate-trail u1 u5)
```

#### Completing a Trail
```clarity
(contract-call? .fitness-trail-explorer complete-trail u1 u3600) ;; 1 hour in seconds
```

#### Getting Trail with Rating
```clarity
(contract-call? .fitness-trail-explorer get-trail-with-rating u1)
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u400 | ERR-INVALID-DIFFICULTY | Difficulty must be 1-5 |
| u401 | ERR-UNAUTHORIZED | Insufficient permissions |
| u402 | ERR-INVALID-RATING | Rating must be 1-5 |
| u404 | ERR-NOT-FOUND | Trail not found or inactive |
| u409 | ERR-TRAIL-EXISTS | Trail ID already exists |

## Development Roadmap

### Phase 3 (Future)
- Trail categories and tagging system
- Photo/media attachments for trails
- Social features (following users, leaderboards)
- Trail difficulty verification through community consensus
- Integration with fitness tracking APIs
- Mobile app development

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

The contract includes comprehensive test coverage for:
- Trail creation and validation
- Rating system functionality
- User statistics tracking
- Security and access controls
- Error handling scenarios

Run tests with:
```bash
clarinet test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- Built on [Stacks](https://www.stacks.co/) blockchain
- Developed with [Clarinet](https://github.com/hirosystems/clarinet)
- Inspired by the need for decentralized fitness community platforms
