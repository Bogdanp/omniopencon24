#lang at-exp slideshow

(require pict
         slideshow/code
         slideshow/text)

(define (author+email name email)
  (vc-append
   (t name)
   (colorize (t email) "gray")))

(define-syntax-rule (with-code-size size body0 body ...)
  (parameterize ([get-current-code-font-size (lambda () size)])
    body0 body ...))

(define bitly-link
  @t{bit.ly/continuationz})

(slide
 @titlet{Continuations: What Have They Ever Done for Us?}
 @author+email["Bogdan Popa"]{bogdan@"@"defn.io})

(slide
 @t{Based on a paper published in FUNARCH '24}
 @t{Co-authored with Marc Kaufmann of CEU Austria}
 @|bitly-link|)

(slide
 #:title @~a{Congame: Platform for Economics Experiments}

 'next
 'next

 @bit{Congame: expand the range of possible experiments}

 'next
 @item{to large numbers of interacting participants,}
 'next
 @item{over long time periods and multiple sessions,}
 'next
 @item{with many, overlapping treatments,}
 'next
 @item{personalized to each participant,}
 'next
 @item{while tracking multi-dimensional outcomes.}
 'next

 @para{Requires strong @it{composability} and @it{reusability}.})

(slide
 #:title @~a{Why a Custom Platform?}

 'next
 @para{Existing tools have low composability and reusability, due to no or poor notion of study.}

 'next
 @item{Web frameworks (e.g., Django, PHP, React):}
 @subitem{Expose too much @it{Web} (requests, DB, ...).}
 'next
 @item{Qualtrics: clicky-clicky gooey interface.}
 'next
 @item{oTree (main inspiration of Congame)})

#;(slide
 #:title @~a{Why Congame?}
 @item{Automatically tracks participants}
 'next
 @item{Notion of @it{study} and @it{step}}
 @subitem{Recursive and composable}
 @subitem{Can be generated dynamically}
 'next
 @item{Full power of Racket available (almost) anywhere}
 'next
 @item{Notion of @it{study} scope for variables}
 @subitem{Imitates @it{lexical} scope})

(slide
 #:title @~a{Why Continuations?}

 @para{How do continuations relate to this?}
 'next
 @item{Congame is written in @it{Racket} and uses @it{continuations}.}
 'next
 @item{These continuations enable multiple benefits:}
 'next
 @subitem{use full power of Racket anywhere;}
 'next
 @subitem{composable notion of @it{study};} ;; Marc: say it is recursive and can be generated dynamically.
 'next
 @subitem{direct style that abstracts over request/response.})


(slide
 #:title @~a{Illustration: Comparison to oTree}

 (let ([otree-code (bitmap "oTree-code.png")])
   (vc-append
    5
    @t{Heavily edited oTree code for Coin-Toss Game:}
    (scale otree-code 0.38))))

(slide
 #:title @~a{Illustration: Comparison to oTree}
 @para{1. Non-local code:}
 @item{Local actions split across files.}

 'next

 @para{2. Clumsy data sharing via global namespace:}
 @item{Reusing app will overwrite `ok`.}

 'next
 @para{3. Reusing apps by duplicating app folder}
 @item{Create app `Choices2`, duplicating substantial code from `Choices1`.})


 ;@item{Non-local code: split up across settings, choices, results.}
 ;@item{Global namespace for data sharing between apps.}
 ;@item{Repetitions of task are tedious.}

(slide
 #:title @~a{Illustration: Comparison to oTree}

 @para{Congame code for "Guessing a Coin Toss":}
 'alts
 (with-code-size 20
   (let ([coin-toss-code-1
          (code
           (defvar guess)
           (defvar toss)

           (defstep (heads-or-tails)
             (set! toss (random-ref '("h" "t")))
             (md
              (form
               (set! guess (radios '(("h" . "Heads")
                                     ("t" . "Tails"))
                                   "Guess Heads or Tails"))
               submit-button)))

           (defstep (result)
             @md{You chose @(if (equal? guess toss) "right" "wrong").})

           (defstudy illustration
             [heads-or-tails --> result]))]
         [coin-toss-code-2
          (code
           (defvar guess)
           (defvar toss)

           (defstep (heads-or-tails)
             (set! toss (random-ref '("h" "t")))
             (md
              (form
               (set! guess (radios '(("h" . "Heads")
                                     ("t" . "Tails"))
                                   "Guess Heads or Tails"))
               submit-button)))

           (defstep (result)
             (md "You chose" @(if (equal? guess toss) "right" "wrong") "."
                 (button "Next")))

           (defstudy coin-toss
             [heads-or-tails --> result])

           (defstudy illustration
             [(coin-toss-1 coin-toss) --> (coin-toss-2 coin-toss)]))])
     (list
      (list coin-toss-code-1)
      (list coin-toss-code-2)))))

(slide
 #:title @~a{Illustration: Comparison to oTree}

 @para{Difference stems from:}

 @item{better notion and data structure of @it{study}}
 @item{and availability of full power of Racket.}

 'next
 @para{Both flow directly from the use of continuations.}

 @item{Continuations are @it{sufficient}, not @it{necessary}.})

(slide ;; Bogdan
 #:title @~a{Continuations on the Web}
 @t{Web programming with continuations simplifies control flow.}
 'next
 'alts
 (with-code-size 15
   (let ([example-without-continuations
          (code
           (define (guess-page req)
             (define n (random 1 100))
             (add-cookie
              "n" (number->string n)
              (response/xexpr
               `(form
                 ([action "/answer"])
                 (input ([name "guess"]))
                 (button "Submit")))))
           code:blank
           (define (answer-page req)
             (define n
               (let ([s (cookies-ref req "n")])
                 (and s (string->number s))))
             (unless n
               (error "how'd you get here?"))
             (define guess
               (string->number (form-ref req "guess")))
             (response/xexpr
              (cond
                [(= guess n) "You guessed right."]
                [(< guess n) "Your guess was too low."]
                [(> guess n) "Your guess was too high."])))
           code:blank
           (register-route! "/" guess-page)
           (register-route! "/answer" answer-page))]
         [example-with-continuations
          (code
           (define (guess-page req)
             (define n (random 1 100))
             (define next-req
               (send/suspend
                (lambda (k-url)
                  (response/xexpr
                   `(form
                     ([action ,k-url])
                     (input ([name "guess"]))
                     (button "Submit"))))))
             (define guess
               (string->number (form-ref next-req "guess")))
             (response/xexpr
              (cond
                [(= guess n) "You guessed right."]
                [(< guess n) "Your guess was too low."]
                [(> guess n) "Your guess was too high."])))
           code:blank
           (register-route! "/" guess-page))])
     (list
      (list
       @t{Instead of:}
       example-without-continuations)
      (list
       (ht-append
        (vc-append
         10
         @t{Instead of:}
         example-without-continuations)
        (vc-append
         10
         @t{We can write:}
         example-with-continuations)))))))

(slide ;; Bogdan
 #:title @~a{Mini Congame}
 'alts
 (let ([mini-congame
        (lambda ()
          (code
           (define current-embed (make-parameter #f))
           (struct step (handler))
           (struct study (steps))
           (define (run-study the-study)
             (let loop ([steps (study-steps the-study)])
               (if (null? steps)
                   '(continue)
                   (match (begin0 (run-step (car steps))
                            (redirect/get/forget))
                     ['(retry) (loop steps)]
                     ['(continue) (loop (cdr steps))]))))
           (define (run-step the-step)
             (match the-step
               [(step (? study? substudy))
                (run-study substudy)]
               [(step handler)
                (send/suspend/dispatch
                 (lambda (embed)
                   (parameterize ([current-embed embed])
                     (response/xexpr (handler)))))]))))]
       [button-widget
        (lambda ()
          (code
           (define (button label [action void])
             `(a
               ([href ,((current-embed)
                        (lambda (req)
                          (action)
                          '(continue)))])
               ,label))))]
       [form-widget
        (lambda ()
          (code
           (define (form e [action (λ (req) #t)])
             `(form
               ([action ,((current-embed)
                          (lambda (req)
                            (if (action req)
                                '(continue)
                                '(retry))))]
                [method "POST"])
               ,e))))]
       [example-study
        (lambda ()
          (code
           (define (hello)
             `(div
               (p "Welcome to the study.")
               ,(button "Continue")))
           code:blank
           (define (done)
             `(p "Thank you for participating."))
           code:blank
           (define example-study
             (study
              (list
               (step hello)
               (step done))))
           code:blank
           (define (study-page req)
             (run-study example-study))
           (register-route! "/study" study-page)))])
   (list
    (list
     @t{The core of Congame is:}
     'next
     @item{Studies, represented as trees of @italic{steps} and sub-studies.}
     'next
     @item{A servlet that traverses a given study, implemented using continuations.}
     'next
     @item{Widgets that let a participant interact with the study.})
    (list
     (with-code-size 24
       (mini-congame)))
    (list
     (with-code-size 24
       (vc-append
        20
        (button-widget)
        (form-widget))))
    (list
     (with-code-size 24
       (example-study))))))

(slide ;; Bogdan
 #:title @~a{Challenge: Dynamic Variables}
 'alts
 (let ([thread-example
        (with-code-size 20
          (code
           (define p (make-parameter #f))
           (define tag (make-continuation-prompt-tag))
           (define k-ch (make-channel))
           (void
            (thread
             (lambda ()
               (call-with-continuation-prompt
                (lambda ()
                  (parameterize ([p 'p1])
                    (p 'p2)
                    ((call-with-current-continuation
                      (lambda (k)
                        (thunk (channel-put k-ch k)))
                      tag))))
                tag))))
           (thread-wait
            (thread
             (lambda ()
               (define k (channel-get k-ch))
               (call-with-continuation-prompt
                (lambda ()
                  (k (λ () (printf "~s~n" (p)))))
                tag))))))]
       [cont-example-1
        (with-code-size 20
          (code
           (define a (make-parameter #f))
           (define b (make-parameter #f))
           (define tag (make-continuation-prompt-tag))
           (define k
             (parameterize ([a 'a])
               (call-with-continuation-prompt
                (lambda ()
                  ((call-with-current-continuation
                    (λ (k) (thunk k))
                    tag)))
                tag)))
           (call-with-continuation-prompt
            (lambda ()
              (k (lambda ()
                   (printf "~s ~s~n" (a) (b)))))
            tag)))]
       [cont-example-2
        (with-code-size 20
          (code
           (define a (make-parameter #f))
           (define b (make-parameter #f))
           (define tag (make-continuation-prompt-tag))
           (define k
             (parameterize ([a 'a])
               (call-with-continuation-prompt
                (lambda ()
                  (parameterize ([b 'b])
                    ((call-with-current-continuation
                      (λ (k) (thunk k))
                      tag))))
                tag)))
           (call-with-continuation-prompt
            (lambda ()
              (k (lambda ()
                   (printf "~s ~s~n" (a) (b)))))
            tag)))])
   (list
    (list
     @para{Racket has dynamic variable support via ``parameters''.}
     'next
     @item{Parameters are thread-specific and continuation-specific.}
     'next
     @item{New threads inherit the parameterizations of their parent threads.}
     'next
     @item{In Congame, we use parameters to track the user's current position in a study.})
    (list
     @item{Parameters are created using @code[make-parameter]:}
     'next
     (with-code-size 24
       (code
        (define current-directory
          (make-parameter #f))))
     'next
     @item{Parameters can be changed using the @code[parameterize] form:}
     (with-code-size 24
       (code
        (parameterize ([current-directory "/home/bogdan"])
          (displayln (current-directory)))))
     'next
     @item{Or by using direct assignment:}
     (with-code-size 24
       (code (current-directory "/home/bogdan")))
     'next
     @item{Direct assignment mutates the thread-local state directly
                  without affecting any surrounding parameterizations.})
    (list
     @para{Thread specific:}
     (with-code-size 24
       (code
        (define current-position
          (make-parameter null))
        code:blank
        (parameterize ([current-position '(root study-1)])
          (thread
           (lambda ()
             (displayln (current-position))
             (current-position '(root study-1 study-2))
             (displayln (current-position)))))
        code:blank
        (thread
         (lambda ()
           (displayln (current-position))))
        code:blank
        (code:comment "Output:")
        (code:comment "t1: (root study-1)")
        (code:comment "t1: (root study-1 study-2)")
        (code:comment "t2: ()"))))
    (list
     @para{Parameter loss:}
     thread-example)
    (list
     @para{Parameter loss:}
     (ht-append 20
      thread-example
      (with-code-size 20
        (code
         (code:comment "Output:")
         (code:comment "p1")))))
    (list
     @para{Continuations + parameters:}
     cont-example-1)
    (list
     @para{Continuations + parameters:}
     (vl-append 20
      cont-example-1
      (with-code-size 20
        (code
         (code:comment "Output:")
         (code:comment "#f #f")))))
    (list
     @para{A surprising interaction:}
     cont-example-2)
    (list
     @para{A surprising interaction:}
     (vl-append 20
      cont-example-2
      (with-code-size 20
        (code
         (code:comment "Output:")
         (code:comment "a b"))))))))

(slide ;; Marc & Bogdan: highlight costs of working in it, not just "is it possible"
 ;; Continuations mean we don't have to make an architectural decision.
 ;; No extra costs from picking the most appropriate data structure.
 #:title @~a{Reflections & Recommendations}
 'alts
 (list
  (list
   'next
   @item{Continuations let us implement our study harness as a straightforward depth-first traversal of a tree.}
   'next
   @item{Less powerful language features, such as coroutines might offer similar benefits.}
   'next
   @item{The issues we encountered were mostly due to some surprising interactions between dynamic variables and delimited continuations.}
   'next
   @item{It would be nice if continuations were inspectable at runtime to aid with debugging.})))

(slide
 @titlet{Thanks!}
 @|bitly-link|
 @t{defn.io})
