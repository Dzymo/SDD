## ADDED Requirements

### Requirement: Status endpoint reports availability

The system SHALL provide a public status endpoint that returns a successful response while the service is available.

#### Scenario: Service is available

- **WHEN** a consumer requests the status endpoint while the service is available
- **THEN** the system returns a successful response
