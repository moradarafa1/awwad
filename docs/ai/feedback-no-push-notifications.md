---
name: feedback-no-push-notifications
description: "owner does not want cloud scheduled tasks / routines pushing notifications to any device; account-wide push cannot be limited to one laptop, so disable PushNotification calls entirely rather than risk it"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 703e356f-74ea-4703-bc33-3f98f726e92e
---

Never call the PushNotification tool at all, from any session, scheduled or interactive (e.g. [[project_wabl_monitor]], [[project_awwad]]), unless the owner explicitly re-enables it.

**Why:** the owner asked (2026-07-20) that no routine send notifications to any phone/browser logged into this Claude account — only this laptop. There is no way to target push notifications to a single device; they go out account-wide. Given that constraint, the owner's explicit fallback was: send no notification at all, they will check the routine's output manually each day. He RESTATED this on 2026-07-20 after an Awwad scheduled run ("لا ترسل اي اشعارات الا على هذا الجهاز او لا ترسل اشعارات ابدا"), which makes it a standing rule he actively polices, not a one-off preference. Since the "only this device" half is technically impossible, the rule collapses to: send none.

**How to apply:** never invoke PushNotification. When building or editing any scheduled task (CronCreate or the scheduled-tasks MCP) for this owner, do not add a PushNotification step, and remove one if a task already has it, unless the owner asks to bring it back (and confirms he's okay with it going to all devices). Report by writing the summary as normal output text instead; he reads it on the laptop. This applies account-wide, to every project and every chat, not just the wabl monitor.

**Not covered by this rule:** the notification features Claude BUILDS into the owner's products (e.g. Awwad's local reminders, adhan alerts and the «تم»/«أمهلني» action buttons). Those are his own product requirements and are unaffected; the rule is only about Claude pushing notifications to him.

**Restated again 2026-07-20** (third time), broadened explicitly to "this or anything else, whatever chat or session it is" — a fully general, permanent rule, not scoped to one routine. Also apply it to the scheduled-tasks MCP's own `notifyOnCompletion` field: set it to `false` on every scheduled task (new or existing) for this owner, not just skip the separate PushNotification tool. Any progress report belongs as a normal chat message inside whichever session is running, nothing else.
