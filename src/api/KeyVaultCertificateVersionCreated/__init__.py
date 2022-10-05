import os
import json
import logging
import json
import base64
import azure.functions as func

from azure.identity import DefaultAzureCredential
from azure.keyvault.certificates import CertificateClient
from azure.mgmt.iothub import IotHubClient, models

def main(event: func.EventGridEvent):
    # result = json.dumps({
    #     'id': event.id,
    #     'data': event.get_json(),
    #     'topic': event.topic,
    #     'subject': event.subject,
    #     'event_type': event.event_type,
    # })

    try:
        subscription_id = os.environ["SUBSCRIPTION_ID"]
        resource_group_name = os.environ["RESOURCE_GROUP_NAME"]
        iothub_name = os.environ["IOTHUB_NAME"]

        event_data = event.get_json()
        keyvault_name = event_data["VaultName"]
        secret_name = event_data["ObjectName"]
        keyvault_uri = f"https://{keyvault_name}.vault.azure.net"

        logging.info(f"Retrieving secret {secret_name} from {keyvault_name}.")
        credential = DefaultAzureCredential()
        akv_certificate_client = CertificateClient(vault_url=keyvault_uri, credential=credential)
        x509_certificate = akv_certificate_client.get_certificate(secret_name)
        x509_base64 = base64.b64encode(x509_certificate.cer).decode("UTF-8")

        logging.info(f"Uploading certificate {secret_name} to IoTHub {iothub_name}.")
        iothub_client = IotHubClient(credential, subscription_id)
        cert_properties = models.CertificateProperties(is_verified=True, certificate=x509_base64)
        cert_description = models.CertificateDescription(properties=cert_properties)
        iothub_client.certificates.create_or_update(resource_group_name, iothub_name, secret_name, cert_description)

        logging.info("Done!")
    except Exception as ex:
        logging.error(ex)