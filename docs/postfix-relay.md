# Postfix-based internal SMTP Relay

The internal SMTP relay may be used to provide your in-cluster services/applications with an internal, open-relay SMTP server.

This is useful when you need to build a bridge between your internal services and your actual SMTP service for some reason.

For example, a lot of public mail sending services have already deprecated TLS v1, v1.1 and v1.2 which is a problem for Java 8 applications since the maximum they can use is TLS v1.2.

In cases like this, your application can send email traffic to your internal smtp-relay which will properly use latest TLS when communicating with the upstream STMP service (your actual SMTP service like Mailgun or Mailu)

# Configuration

When you want to utilize postfix-relay, you will need to set the POSTFIX_RELAY_SMTP_* variables which are the parameters of your actual SMTP service (to which Postfix will need to relay the email messages).

They are named similarly to the SMTP_* variables.

~~~
cexport POSTFIX_RELAY_SMTP_HOST "smtp.mailgun.org"
cexport POSTFIX_RELAY_SMTP_PORT "587"
cexport POSTFIX_RELAY_SMTP_USERNAME "postmaster@sandboxXXXXX.mailgun.org"
cexport POSTFIX_RELAY_SMTP_PASSWORD "xxxx"
~~~

Then, you instruct SolaKube deployers to use this internal SMTP service:

~~~
cexport SMTP_HOST "smtp.postfix-relay"
cexport SMTP_PORT "25"
cexport SMTP_USERNAME "none"
cexport SMTP_PASSWORD "none"
~~~


# Deployment

~~~
sk deploy postfix-relay
~~~
