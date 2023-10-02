# import mailchimp_transactional as MailchimpTransactional
# from mailchimp_transactional.api_client import ApiClientError
from mailchimp_marketing import Client

import logging
import ml_config

_mailchimp = False
_configEmail = None

def Setup(apiKey, serverPrefix, configEmail):
    global _mailchimp
    global _configEmail

    # _mailchimp = MailchimpTransactional.Client(apiKey)
    _mailchimp = Client()
    _mailchimp.set_config({
      "api_key": apiKey,
      "server": serverPrefix,
    })
    # try:
    #     response = _mailchimp.ping.get()
    #     print('API called successfully: {}'.format(response))
    # # except ApiClientError as error:
    # except Exception as err:
    #     # print("An exception occurred: {}".format(error.text))
    #     print ('error', err, apiKey)
    _configEmail = configEmail

def Send(subject, body, toEmails, from1=None, cc="", bcc="", trackOpens = True):
    global _mailchimp
    global _configEmail
    from1 = from1 if from1 is not None else _configEmail['from']
    logger = logging.getLogger('default-logger')
    if not _mailchimp:
        logger.warn('email_mailchimp not setup. No email will be sent.')
        return

    if isinstance(toEmails, str):
        toEmails = [toEmails]
    to = []
    for toEmail in toEmails:
        to.append({ 'email': toEmail })
    try:
        response = _mailchimp.messages.send({"message": {
            'html': body,
            'subject': subject,
            'from_email': from1,
            'to': to,
            'track_opens': trackOpens,
        }})
        print(response)
    except ApiClientError as error:
        print("An exception occurred: {}".format(error.text))
