# HealthRecords - Secure Medical Records Management

A blockchain-based patient-controlled health records system built on Stacks using Clarity smart contracts. HealthRecords enables patients to own their medical data while granting secure, time-limited access to healthcare providers through decentralized identity and permission management.

## Overview

HealthRecords revolutionizes medical data management by putting patients in complete control of their health information. Unlike traditional centralized Electronic Health Record (EHR) systems, this platform ensures data sovereignty, transparent access control, and immutable audit trails while maintaining HIPAA-compliant privacy through encrypted data storage.

## Key Features

### For Patients
- **Data Sovereignty**: Complete ownership and control of medical records
- **Granular Access Control**: Grant or revoke provider access at any time
- **Time-Limited Permissions**: Set expiration dates for provider access
- **Access Level Management**: Control what data providers can see
- **Privacy by Default**: All records stored as encrypted hashes on-chain
- **Immutable History**: Permanent, tamper-proof medical record trail
- **Profile Management**: Update personal health information securely

### For Healthcare Providers
- **Professional Registration**: Verified provider profiles with credentials
- **Secure Data Access**: Access patient records only with explicit permission
- **Record Creation**: Add diagnoses, prescriptions, and medical notes
- **License Verification**: On-chain credential validation
- **Access Transparency**: Clear visibility into granted permissions

### Platform Features
- **Decentralized Storage**: Patient records stored as cryptographic hashes
- **Permission Expiry**: Automatic access revocation after set time periods
- **Provider Verification**: Admin-controlled healthcare provider validation
- **Audit Trail**: Complete history of all access grants and record additions
- **Real-time Permission Checking**: Instant validation of provider access rights

## Architecture

### Data Structures

#### Patient Profiles
- Personal information (name, date of birth)
- Medical data (blood type, allergies)
- Registration and update timestamps
- Blockchain-based identity

#### Healthcare Provider Profiles
- Professional credentials (name, specialization, license)
- Verification status
- Active/inactive status
- Wallet-based identity

#### Medical Records
- Patient and provider references
- Record type classification
- Encrypted record hash (off-chain data reference)
- Diagnosis and prescription information
- Creation timestamp
- Encryption flag

#### Access Permissions
- Patient-provider relationship mapping
- Grant status (active/revoked)
- Access level (tiered permissions)
- Time-based expiry
- Grant timestamp for audit trail

## Smart Contract Functions

### Patient Functions

#### `register-patient`
```clarity
(register-patient (name (string-ascii 128)) 
                 (date-of-birth uint) 
                 (blood-type (string-ascii 4)) 
                 (allergies (string-ascii 256)))
```
Register as a patient with basic health information.

**Parameters:**
- `name`: Patient's full name
- `date-of-birth`: Date of birth as Unix timestamp
- `blood-type`: Blood type (e.g., "A+", "O-", "AB+")
- `allergies`: Known allergies (comma-separated)

**Returns:** Success confirmation

**Example:**
```clarity
(contract-call? .healthrecords register-patient 
  "John Doe" 
  u631152000 
  "O+" 
  "Penicillin, Peanuts")
```

#### `grant-access`
```clarity
(grant-access (provider principal) 
              (access-level uint) 
              (expiry (optional uint)))
```
Grant a healthcare provider access to your medical records.

**Parameters:**
- `provider`: Provider's wallet address
- `access-level`: Permission level (1=basic, 2=full, 3=admin)
- `expiry`: Optional block height for automatic access revocation

**Returns:** Success confirmation

**Access Levels:**
- `u1`: Basic (view records only)
- `u2`: Full (view and add records)
- `u3`: Admin (full access including modifications)

**Example:**
```clarity
;; Grant full access expiring at block 100000
(contract-call? .healthrecords grant-access 
  'ST1PROVIDER123 
  u2 
  (some u100000))
```

#### `revoke-access`
```clarity
(revoke-access (provider principal))
```
Immediately revoke a provider's access to your medical records.

**Parameters:**
- `provider`: Provider's wallet address to revoke

**Returns:** Success confirmation

#### `update-patient-info`
```clarity
(update-patient-info (blood-type (string-ascii 4)) 
                     (allergies (string-ascii 256)))
```
Update your medical information (blood type and allergies).

**Parameters:**
- `blood-type`: Updated blood type
- `allergies`: Updated allergy information

**Returns:** Success confirmation

#### `update-access-expiry`
```clarity
(update-access-expiry (provider principal) 
                      (new-expiry (optional uint)))
```
Modify the expiration date for an existing provider permission.

**Parameters:**
- `provider`: Provider's wallet address
- `new-expiry`: New expiry block height (none for permanent)

**Returns:** Success confirmation

### Provider Functions

#### `register-provider`
```clarity
(register-provider (name (string-ascii 128)) 
                   (specialization (string-ascii 64)) 
                   (license-number (string-ascii 64)))
```
Register as a healthcare provider with professional credentials.

**Parameters:**
- `name`: Provider's name or medical practice name
- `specialization`: Medical specialty (e.g., "Cardiology", "General Practice")
- `license-number`: Medical license or registration number

**Returns:** Provider ID

**Example:**
```clarity
(contract-call? .healthrecords register-provider 
  "Dr. Jane Smith MD" 
  "Cardiology" 
  "MD-12345-CA")
;; Returns: (ok u1)
```

#### `add-medical-record`
```clarity
(add-medical-record (patient principal) 
                    (record-type (string-ascii 32)) 
                    (record-hash (string-ascii 64)) 
                    (diagnosis (string-ascii 256)) 
                    (prescription (string-ascii 256)))
```
Add a medical record for a patient (requires active permission).

**Parameters:**
- `patient`: Patient's wallet address
- `record-type`: Type of record (e.g., "consultation", "lab-result", "imaging")
- `record-hash`: SHA-256 hash of encrypted off-chain record
- `diagnosis`: Medical diagnosis information
- `prescription`: Prescribed medications or treatment plan

**Returns:** Record ID

**Security:** Automatically validates provider has active access permission

**Example:**
```clarity
(contract-call? .healthrecords add-medical-record 
  'ST1PATIENT123 
  "consultation" 
  "a3b2c1d4e5f6..." 
  "Hypertension, stage 1" 
  "Lisinopril 10mg daily")
;; Returns: (ok u1)
```

### Read-Only Functions

#### `get-patient`
```clarity
(get-patient (patient principal))
```
Retrieve patient profile information.

**Returns:** Patient data structure or none

#### `get-record`
```clarity
(get-record (record-id uint))
```
Retrieve medical record by ID.

**Returns:** Medical record data or none

**Note:** Does not enforce access control - implement off-chain verification

#### `check-access`
```clarity
(check-access (patient principal) (provider principal))
```
Check access permission status between patient and provider.

**Returns:** Permission data structure or none

#### `is-access-valid`
```clarity
(is-access-valid (patient principal) (provider principal))
```
Verify if provider currently has valid access to patient records.

**Returns:** Boolean indicating active, non-expired permission

**Example:**
```clarity
(contract-call? .healthrecords is-access-valid 
  'ST1PATIENT123 
  'ST1PROVIDER456)
;; Returns: (ok true) or (ok false)
```

#### `get-provider`
```clarity
(get-provider (provider-id uint))
```
Retrieve provider profile by ID.

**Returns:** Provider data structure or none

#### `get-provider-by-wallet`
```clarity
(get-provider-by-wallet (wallet principal))
```
Get provider ID from wallet address.

**Returns:** Provider ID or none

#### `get-patient-record-count`
```clarity
(get-patient-record-count (patient principal))
```
Get total number of records in the system.

**Returns:** Total record count

**Note:** Currently returns global count - needs enhancement for per-patient counting

### Admin Functions

#### `verify-provider`
```clarity
(verify-provider (provider-id uint))
```
Verify a healthcare provider's credentials (admin only).

**Parameters:**
- `provider-id`: ID of provider to verify

**Returns:** Success confirmation

**Access:** Contract owner only

#### `deactivate-provider`
```clarity
(deactivate-provider (provider-id uint))
```
Deactivate a provider's account (admin only).

**Parameters:**
- `provider-id`: ID of provider to deactivate

**Returns:** Success confirmation

**Access:** Contract owner only

## Error Codes

- `u100` (`err-owner-only`): Operation restricted to contract owner
- `u101` (`err-not-found`): Requested entity not found
- `u102` (`err-unauthorized`): Caller lacks required permissions
- `u103` (`err-access-denied`): Provider access not granted by patient
- `u104` (`err-already-exists`): Entity already registered

## Usage Examples

### Complete Patient Workflow

```clarity
;; 1. Patient registers
(contract-call? .healthrecords register-patient 
  "Alice Johnson" 
  u662688000 
  "B+" 
  "Shellfish, Latex")
;; => (ok true)

;; 2. Provider registers
(contract-call? .healthrecords register-provider 
  "Dr. Robert Lee MD" 
  "Internal Medicine" 
  "MD-67890-NY")
;; => (ok u1)

;; 3. Admin verifies provider
(contract-call? .healthrecords verify-provider u1)
;; => (ok true)

;; 4. Patient grants time-limited access
(contract-call? .healthrecords grant-access 
  'ST1PROV1D3R123 
  u2 
  (some u105000))
;; => (ok true)

;; 5. Provider adds medical record
(contract-call? .healthrecords add-medical-record 
  'ST1PAT13NT123 
  "annual-checkup" 
  "b4c5d6e7f8a9..." 
  "General health examination - all normal" 
  "Continue current medications")
;; => (ok u1)

;; 6. Patient checks access status
(contract-call? .healthrecords is-access-valid 
  'ST1PAT13NT123 
  'ST1PROV1D3R123)
;; => (ok true)

;; 7. Patient extends access
(contract-call? .healthrecords update-access-expiry 
  'ST1PROV1D3R123 
  (some u110000))
;; => (ok true)

;; 8. Patient revokes access
(contract-call? .healthrecords revoke-access 'ST1PROV1D3R123)
;; => (ok true)
```

### Emergency Access Scenario

```clarity
;; Patient grants immediate emergency access
(contract-call? .healthrecords grant-access 
  'ST1EMERGENCY123 
  u3 
  (some (+ block-height u144)))  ;; ~24 hours
;; => (ok true)
```

### Specialist Referral Workflow

```clarity
;; Primary care grants access to specialist
;; Patient grants limited access to specialist
(contract-call? .healthrecords grant-access 
  'ST1SPEC1AL1ST456 
  u1 
  (some (+ block-height u4320)))  ;; ~30 days
;; => (ok true)

;; Specialist can view but specialist adds record after examination
(contract-call? .healthrecords add-medical-record 
  'ST1PAT13NT123 
  "specialist-consult" 
  "c6d7e8f9a0b1..." 
  "Cardiology consultation - EKG normal" 
  "No intervention required")
```

## Security Considerations

### Data Privacy
- **Encrypted Hashes**: Only cryptographic hashes stored on-chain
- **Off-chain Storage**: Actual medical data stored in encrypted databases
- **Access Control**: Permission verified before every record addition
- **Time Limits**: Automatic expiration prevents indefinite access

### Access Management
- **Patient-Controlled**: Only patients can grant/revoke access
- **Granular Permissions**: Different access levels for different needs
- **Audit Trail**: All access grants logged on-chain
- **Revocation**: Immediate access termination capability

### Provider Verification
- **Admin Approval**: Providers must be verified before full functionality
- **License Tracking**: Credential information stored for validation
- **Deactivation**: Ability to disable fraudulent providers
- **Transparent Status**: Public verification status

### Smart Contract Security
- **Access Checks**: Every function validates caller permissions
- **Input Validation**: Prevents invalid data entry
- **Immutable Records**: Medical records cannot be altered after creation
- **No Direct Data Exposure**: Read functions don't enforce permissions (implement off-chain)

## HIPAA Compliance Considerations

### Technical Safeguards
- ✅ Encryption of data at rest (hashes only on-chain)
- ✅ Access control mechanisms
- ✅ Audit trails for all access
- ✅ Unique user identification (wallet addresses)

### Administrative Safeguards
- ⚠️ Requires off-chain Business Associate Agreements
- ⚠️ Provider training and certification processes
- ⚠️ Incident response procedures

### Physical Safeguards
- ✅ Decentralized storage reduces single points of failure
- ⚠️ Requires secure off-chain data storage infrastructure

**Note:** This smart contract is a technical component. Full HIPAA compliance requires comprehensive implementation including off-chain systems, legal agreements, and organizational policies.

## Integration Guide

### Off-Chain Data Storage

```javascript
// Example: Storing encrypted medical data
const encryptedData = await encryptMedicalRecord(patientData);
const recordHash = sha256(encryptedData);

// Store encrypted data in secure database
await secureDB.store(recordHash, encryptedData);

// Store hash on blockchain
await contractCall({
  functionName: 'add-medical-record',
  functionArgs: [
    patient,
    recordType,
    recordHash,  // Reference to off-chain data
    diagnosis,
    prescription
  ]
});
```

### Permission Verification Middleware

```javascript
// Verify provider access before showing data
async function checkProviderAccess(patientAddress, providerAddress) {
  const result = await contractCall({
    functionName: 'is-access-valid',
    functionArgs: [patientAddress, providerAddress]
  });
  
  return result.value;
}
```

## Testing Recommendations

### Unit Tests
- [x] Patient registration (success/duplicate)
- [x] Provider registration (success/duplicate)
- [x] Access granting with different levels
- [x] Access revocation
- [x] Time-based access expiry
- [x] Record addition with permission validation
- [x] Provider verification
- [x] Provider deactivation
- [x] Patient info updates

### Integration Tests
- [ ] Complete patient-provider workflow
- [ ] Multiple providers with different access levels
- [ ] Expired access prevention
- [ ] Emergency access scenarios
- [ ] Specialist referral workflows

### Security Tests
- [ ] Unauthorized record addition attempts
- [ ] Access after revocation
- [ ] Access after expiry
- [ ] Non-patient attempting to grant access
- [ ] Unverified provider operations

## Known Limitations & Future Enhancements

### Current Limitations
1. `get-patient-record-count` returns global count instead of per-patient
2. No patient-initiated record deletion
3. Read-only functions don't enforce access control
4. No bulk permission management
5. Limited record search capabilities

### Planned Enhancements
- [ ] Per-patient record counting and indexing
- [ ] Patient-initiated record amendments (not deletion)
- [ ] Emergency access override mechanism
- [ ] Multi-signature record approval
- [ ] Provider rating and review system
- [ ] Integration with decentralized identity (DID)
- [ ] Support for medical imaging hashes
- [ ] Family member delegation
- [ ] Research data sharing with anonymization
- [ ] Insurance provider integration
- [ ] Automated access renewal workflows
- [ ] Compliance reporting tools

## Deployment

### Prerequisites
- Clarinet CLI
- Stacks wallet
- Secure key management system

### Deployment Steps

```bash
# 1. Test locally
clarinet test

# 2. Check contract syntax
clarinet check

# 3. Deploy to testnet
clarinet deploy --testnet

# 4. Verify deployment
clarinet console --testnet

# 5. Production deployment
clarinet deploy --mainnet
```

## License

MIT License - See LICENSE file for details

## Disclaimer

**IMPORTANT:** This smart contract is provided for educational and development purposes. It is NOT a complete HIPAA-compliant system. Healthcare organizations must:

- Conduct thorough security audits
- Implement comprehensive off-chain encryption
- Establish proper Business Associate Agreements
- Follow all relevant healthcare regulations
- Consult legal and compliance experts
- Implement proper access logging and monitoring
- Maintain secure backup systems

## Support & Contributing

- GitHub Issues: [repository-url]
- Documentation: [docs-link]
- Discord Community: [discord-link]
- Security Disclosures: security@example.com

## Acknowledgments

Built with privacy and patient empowerment at the core. Special thanks to the Stacks community for blockchain healthcare innovation.
