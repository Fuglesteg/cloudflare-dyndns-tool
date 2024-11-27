(use-modules (web http)
             (web client)
             (ice-9 binary-ports)
             (ice-9 rdelim)
             (ice-9 ftw)
             (ice-9 receive)
             (json)
             (rnrs bytevectors))

(define %zone-id (call-with-input-file "zone.secret" read-line))
(define %token (call-with-input-file "token.secret" read-line))
(define %base-url "https://api.cloudflare.com/client/v4/")

(define* (send-authorized-request uri #:key content (method 'GET))
  (receive (_ content)
      (http-request 
       (string-append %base-url uri)
       #:method method
       #:body content
       #:headers `((Authorization . ,(string-append "Bearer " %token))))
    (json-string->scm (utf8->string content))))

(define get-records
  (lambda _ (vector->list
             (cdr
              (assoc "result"
                     (send-authorized-request
                      (string-append "zones/" %zone-id "/dns_records")))))))

(define (filter-ipv4-records records)
  (filter (lambda (record)
            (string= (cdr (assoc "type" record)) "A")) 
          records))

(define get-ipv4-records
  (lambda _
    (filter-ipv4-records (get-records))))

(define (update-record-ip record-id ip)
  (send-authorized-request 
   (string-append "zones/" %zone-id "/dns_records/" record-id)
   #:method 'PATCH
   #:content (string-append "{\"content\": \"" ip "\"}")))

(define (get-ids-from-records records)
  (map (lambda (record) (cdr (assoc "id" record))) records))

(define get-ipv4-record-ids
  (lambda _
    (get-ids-from-records (get-ipv4-records))))


(define read-ip-from-file
  (lambda _
    (if (file-exists? "ip")
      (call-with-input-file "ip" read-line)
      "")))

(define (write-ip-to-file ip)
  (with-output-to-file "ip"
    (lambda _
      (display ip))))

(define (ip-has-changed? new-ip)
  (not (string= new-ip (read-ip-from-file))))

(define get-ip
  (lambda _
    (receive (_ ip)
        (http-get "https://ipinfo.io/ip")
      ip)))

(define main
  (lambda _
    (display "Fetching current IP...\n")
    (let ((ip (get-ip)))
      (if (not (ip-has-changed? ip))
        (display "IP has not changed, quitting...\n")
        (begin
          (display (string-append "Previous IP: " (read-ip-from-file) "\n"))
          (display (string-append "Current IP: " ip "\n"))
          (for-each 
           (lambda (record-id) (update-record-ip record-id ip))
           (get-ipv4-record-ids))
          (display "Record IPs updated\n")
          (display "Writing new IP to file\n")
          (write-ip-to-file ip))))))

(main)

