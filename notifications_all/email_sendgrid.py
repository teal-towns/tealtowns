import sendgrid
from sendgrid.helpers.mail import Mail
import logging

import ml_config

sg = False
_configEmail = None

def Setup(api_key, configEmail):
    global sg
    global _configEmail
    sg = sendgrid.SendGridAPIClient(api_key)
    _configEmail = configEmail

def Send(subject, body, to, from1=None, cc="", bcc=""):
    global _configEmail
    from1 = from1 if from1 is not None else _configEmail['from']
    logger = logging.getLogger('default-logger')
    if not sg:
        logger.warn('email_sendgrid not setup. No email will be sent.')
        return

    mail = Mail(
        from_email = from1,
        to_emails = to,
        subject = subject,
        html_content = body
    )
    response = sg.send(mail)
    logger.info('email sent to ' + to + ', status: ' + str(response.status_code))