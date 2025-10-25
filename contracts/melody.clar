;; melody-app
;; Clarity contract for a decentralized music playlist sharing platform

(define-data-var playlist-counter uint u0)

(define-map playlists {id: uint}
  {creator: principal,
   song: (string-ascii 50),
   shared-with: (optional principal),
   status: (string-ascii 12)})

;; Create a playlist with a song
(define-public (create-playlist (song (string-ascii 50)))
  (begin
    (asserts! (> (len song) u0) (err u1))
    (let
      (
        (id (var-get playlist-counter))
      )
      (map-set playlists {id: id}
        {creator: tx-sender,
         song: song,
         shared-with: none,
         status: "open"})
      (var-set playlist-counter (+ id u1))
      (ok id)
    )
  )
)

;; Share a playlist with another user
(define-public (share-playlist (id uint) (recipient principal))
  (match (map-get? playlists {id: id})
    playlist
    (if (and (is-eq (get status playlist) "open") (is-eq tx-sender (get creator playlist)))
      (begin
        (map-set playlists {id: id}
          {creator: (get creator playlist),
           song: (get song playlist),
           shared-with: (some recipient),
           status: "shared"})
        (ok "Playlist shared")
      )
      (err u2)) ;; not open or not creator
    (err u3)) ;; playlist not found
)

;; Acknowledge shared playlist
(define-public (acknowledge-playlist (id uint))
  (match (map-get? playlists {id: id})
    playlist
    (if (and (is-eq (get status playlist) "shared") (is-eq tx-sender (unwrap! (get shared-with playlist) (err u4))))
      (begin
        (map-set playlists {id: id}
          {creator: (get creator playlist),
           song: (get song playlist),
           shared-with: (get shared-with playlist),
           status: "acknowledged"})
        (ok "Playlist acknowledged")
      )
      (err u5)) ;; not shared or not recipient
    (err u6)) ;; playlist not found
)