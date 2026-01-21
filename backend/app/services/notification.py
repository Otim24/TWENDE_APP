
class NotificationService:
    @staticmethod
    async def send_sms(phone: str, code: str):
        # In production, this would integrate with Twilio/AfricaTalking
        print(f"\n======== MOCK SMS TO {phone}: {code} ========\n")
        return True

notification_service = NotificationService()
