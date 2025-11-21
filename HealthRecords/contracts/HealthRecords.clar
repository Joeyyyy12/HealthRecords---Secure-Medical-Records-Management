;; HealthRecords - Secure Medical Records Management
;; Patient-controlled health data with provider access management

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-access-denied (err u103))
(define-constant err-already-exists (err u104))

(define-data-var next-record-id uint u1)
(define-data-var next-provider-id uint u1)
(define-data-var total-records uint u0)

(define-map patients
  principal
  {
    name: (string-ascii 128),
    date-of-birth: uint,
    blood-type: (string-ascii 4),
    allergies: (string-ascii 256),
    registered-at: uint,
    last-updated: uint
  }
)

(define-map medical-records
  uint
  {
    patient: principal,
    provider: principal,
    record-type: (string-ascii 32),
    record-hash: (string-ascii 64),
    diagnosis: (string-ascii 256),
    prescription: (string-ascii 256),
    created-at: uint,
    encrypted: bool
  }
)

(define-map access-permissions
  {patient: principal, provider: principal}
  {
    granted: bool,
    granted-at: uint,
    expiry: (optional uint),
    access-level: uint
  }
)

(define-map providers
  uint
  {
    wallet: principal,
    name: (string-ascii 128),
    specialization: (string-ascii 64),
    license-number: (string-ascii 64),
    verified: bool,
    active: bool,
    joined-at: uint
  }
)

(define-map provider-lookup principal uint)

(define-public (register-patient
    (name (string-ascii 128))
    (date-of-birth uint)
    (blood-type (string-ascii 4))
    (allergies (string-ascii 256)))
  (begin
    (asserts! (is-none (map-get? patients tx-sender)) err-already-exists)

    (map-set patients tx-sender {
      name: name,
      date-of-birth: date-of-birth,
      blood-type: blood-type,
      allergies: allergies,
      registered-at: block-height,
      last-updated: block-height
    })

    (print {event: "patient-registered", patient: tx-sender})
    (ok true)
  )
)

(define-public (register-provider
    (name (string-ascii 128))
    (specialization (string-ascii 64))
    (license-number (string-ascii 64)))
  (let ((provider-id (var-get next-provider-id)))
    (asserts! (is-none (map-get? provider-lookup tx-sender)) err-already-exists)

    (map-set providers provider-id {
      wallet: tx-sender,
      name: name,
      specialization: specialization,
      license-number: license-number,
      verified: false,
      active: true,
      joined-at: block-height
    })

    (map-set provider-lookup tx-sender provider-id)
    (var-set next-provider-id (+ provider-id u1))

    (print {event: "provider-registered", provider-id: provider-id})
    (ok provider-id)
  )
)

(define-public (grant-access (provider principal) (access-level uint) (expiry (optional uint)))
  (begin
    (asserts! (is-some (map-get? patients tx-sender)) err-not-found)

    (map-set access-permissions {patient: tx-sender, provider: provider} {
      granted: true,
      granted-at: block-height,
      expiry: expiry,
      access-level: access-level
    })

    (print {event: "access-granted", patient: tx-sender, provider: provider})
    (ok true)
  )
)

(define-public (revoke-access (provider principal))
  (begin
    (map-set access-permissions {patient: tx-sender, provider: provider} {
      granted: false,
      granted-at: block-height,
      expiry: none,
      access-level: u0
    })

    (print {event: "access-revoked", patient: tx-sender, provider: provider})
    (ok true)
  )
)

(define-public (add-medical-record
    (patient principal)
    (record-type (string-ascii 32))
    (record-hash (string-ascii 64))
    (diagnosis (string-ascii 256))
    (prescription (string-ascii 256)))
  (let (
    (record-id (var-get next-record-id))
    (permission (map-get? access-permissions {patient: patient, provider: tx-sender}))
  )
    (asserts! (is-some permission) err-access-denied)
    (asserts! (get granted (unwrap-panic permission)) err-access-denied)

    (map-set medical-records record-id {
      patient: patient,
      provider: tx-sender,
      record-type: record-type,
      record-hash: record-hash,
      diagnosis: diagnosis,
      prescription: prescription,
      created-at: block-height,
      encrypted: true
    })

    (var-set next-record-id (+ record-id u1))
    (var-set total-records (+ (var-get total-records) u1))

    (print {event: "record-added", record-id: record-id, patient: patient})
    (ok record-id)
  )
)

(define-read-only (get-patient (patient principal))
  (map-get? patients patient)
)

(define-read-only (get-record (record-id uint))
  (map-get? medical-records record-id)
)

(define-read-only (check-access (patient principal) (provider principal))
  (ok (map-get? access-permissions {patient: patient, provider: provider}))
)

(define-read-only (get-provider (provider-id uint))
  (map-get? providers provider-id)
)

(define-public (update-patient-info
    (blood-type (string-ascii 4))
    (allergies (string-ascii 256)))
  (let ((patient (unwrap! (map-get? patients tx-sender) err-not-found)))
    (map-set patients tx-sender
      (merge patient {
        blood-type: blood-type,
        allergies: allergies,
        last-updated: block-height
      }))

    (print {event: "patient-info-updated", patient: tx-sender})
    (ok true)
  )
)

(define-public (verify-provider (provider-id uint))
  (let ((provider (unwrap! (map-get? providers provider-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)

    (map-set providers provider-id (merge provider {verified: true}))

    (print {event: "provider-verified", provider-id: provider-id})
    (ok true)
  )
)

(define-public (deactivate-provider (provider-id uint))
  (let ((provider (unwrap! (map-get? providers provider-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)

    (map-set providers provider-id (merge provider {active: false}))

    (print {event: "provider-deactivated", provider-id: provider-id})
    (ok true)
  )
)

(define-public (update-access-expiry (provider principal) (new-expiry (optional uint)))
  (let ((permission (unwrap! (map-get? access-permissions {patient: tx-sender, provider: provider}) err-not-found)))
    (map-set access-permissions {patient: tx-sender, provider: provider}
      (merge permission {expiry: new-expiry}))

    (print {event: "access-expiry-updated", patient: tx-sender, provider: provider})
    (ok true)
  )
)

(define-read-only (get-patient-record-count (patient principal))
  (ok (var-get total-records))
)

(define-read-only (is-access-valid (patient principal) (provider principal))
  (match (map-get? access-permissions {patient: patient, provider: provider})
    permission (ok (and
      (get granted permission)
      (match (get expiry permission)
        expiry-block (<= block-height expiry-block)
        true
      )
    ))
    (ok false)
  )
)

(define-read-only (get-provider-by-wallet (wallet principal))
  (map-get? provider-lookup wallet)
)
