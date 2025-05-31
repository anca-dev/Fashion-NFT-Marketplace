;; Fashion NFT Marketplace Contract
;; Enables minting, trading, and royalty distribution for fashion NFTs

(define-non-fungible-token fashion-nft uint)

(define-data-var next-token-id uint u1)
(define-data-var contract-owner principal tx-sender)

(define-map token-metadata uint {
  name: (string-ascii 64),
  description: (string-ascii 256),
  image-uri: (string-ascii 256),
  designer: principal,
  category: (string-ascii 32),
  rarity: (string-ascii 16)
})

(define-map token-prices uint uint)
(define-map designer-royalties principal uint)

(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INSUFFICIENT-FUNDS (err u402))

(define-public (mint-fashion-nft 
  (name (string-ascii 64))
  (description (string-ascii 256))
  (image-uri (string-ascii 256))
  (category (string-ascii 32))
  (rarity (string-ascii 16))
  (price uint))
  (let ((token-id (var-get next-token-id)))
    (try! (nft-mint? fashion-nft token-id tx-sender))
    (map-set token-metadata token-id {
      name: name,
      description: description,
      image-uri: image-uri,
      designer: tx-sender,
      category: category,
      rarity: rarity
    })
    (map-set token-prices token-id price)
    (map-set designer-royalties tx-sender u10)
    (var-set next-token-id (+ token-id u1))
    (ok token-id)))

(define-public (buy-nft (token-id uint))
  (let ((price (unwrap! (map-get? token-prices token-id) ERR-NOT-FOUND))
        (owner (unwrap! (nft-get-owner? fashion-nft token-id) ERR-NOT-FOUND))
        (metadata (unwrap! (map-get? token-metadata token-id) ERR-NOT-FOUND))
        (designer (get designer metadata))
        (royalty-rate (default-to u10 (map-get? designer-royalties designer)))
        (royalty-amount (/ (* price royalty-rate) u100))
        (seller-amount (- price royalty-amount)))
    (try! (stx-transfer? price tx-sender owner))
    (try! (stx-transfer? royalty-amount owner designer))
    (try! (nft-transfer? fashion-nft token-id owner tx-sender))
    (map-delete token-prices token-id)
    (ok true)))

(define-read-only (get-token-metadata (token-id uint))
  (map-get? token-metadata token-id))

(define-read-only (get-token-price (token-id uint))
  (map-get? token-prices token-id))

(define-read-only (get-next-token-id)
  (var-get next-token-id))