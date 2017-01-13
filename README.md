# Access Tickets (Access Request System)
Access tickets is Access Request System based on Redmine plugin.

Access Request System is a tool for requesting and authorizing access to administrative data in ITS-managed systems and applications.

This plugin made for approving access requests and account access to some assets such as websites, servers and other IT entities.

For more info goto http://www.redmine.org/plugins/access_tickets

Access tickets это решение для учета доступа, основанное на базе плагина для Redmine.

Данное решение предназначено для согласования и учета доступа к веб-сайтам, серверам, базам данных и прочим информационным ресурсам.

Данное решение поможет вам учесть доступ пользователей к ресурсам, провести аудит доступа пользователей и вовремя отключить доступ уволенным сотрудникам.

Для получения более подробной информации перейдите по адресу: http://www.redmine.org/plugins/access_tickets

### Installation:

Clone from GitHub
```sh
cd <redmine_root_directory>/plugins
git clone https://github.com/iymaltsev/access_tickets.git access_tickets
rake redmine:plugins:migrate
```
Or download [ZIP-archive](https://github.com/iymaltsev/access_tickets/archive/master.zip) and extract it into "access_tickets" directory.

Before start using this plugin needs to set base parameters of access_tickets via URL /settings/plugin/access_tickets.

And then set the group leaders (Groupliders can view the access of workers consisting in the respective groups)

Перед началом использования данного плагина необходимо установить его базовые параметры через URL /settings/plugin/access_tickets
А затем установить руководителей групп (Руководители групп могут просматривать доступа работников, состоящих в соответствующих группах)

### Screenshots
![screenshot](http://www.redmine.org/attachments/download/17059/Concept_s.jpg)

![screenshot](http://www.redmine.org/attachments/download/17265/Workflow_grant.jpg)

![screenshot](http://www.redmine.org/attachments/download/16509/resources_list.png)

![screenshot](http://www.redmine.org/attachments/download/16510/change_resource_details.png)

![screenshot](http://www.redmine.org/attachments/download/17222/access_list.png)

### Screenshots from extended version

![screenshot](http://www.redmine.org/attachments/download/17223/ex-access-templates.png)

![screenshot](http://www.redmine.org/attachments/download/17224/ex-access-by-template.png)

![screenshot](http://www.redmine.org/attachments/download/17225/ex-change-access-expire.png)

![screenshot](http://www.redmine.org/attachments/download/17226/ex-template-agreement.png)
