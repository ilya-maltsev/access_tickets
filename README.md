# Access Tickets (Access Request System)
[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/access_tickets)
###
EN:
###
Access tickets is Access Request System based on Redmine plugin.

Access Request System is a tool for requesting and authorizing access to administrative data in ITS-managed systems and applications.

This plugin made for approving access requests and account access to some assets such as websites, servers and other IT entities.

For any questions of this plugin (and for get full plugin version with access templates & simply approvement features, lists of expired access rights & etc) you can send email i.y.maltsev@yandex.ru
###
RU:
###
Access tickets это решение для учета доступа, основанное на базе плагина для Redmine.

Данное решение предназначено для согласования и учета доступа к веб-сайтам, серверам, базам данных и прочим информационным ресурсам.

Данное решение поможет вам учесть доступ пользователей к ресурсам, провести аудит доступа пользователей и вовремя отключить доступ уволенным сотрудникам.

По любым вопросам об этом плагине (например, для получения полной версии плагина с шаблонами доступа, списками истекших прав доступа и многими другими полезными функциями) вы можете связаться со мной по электронной почте i.y.maltsev@yandex.ru

### Installation:
###
EN:
###
Clone from GitHub:
```sh
cd <redmine_root_directory>/plugins
git clone https://github.com/iymaltsev/access_tickets.git access_tickets
```
Or download [ZIP-archive](https://github.com/iymaltsev/access_tickets/archive/master.zip) and extract it into "access_tickets" directory (/var/lib/redmine/plugins/access_tickets).

And migrate plugin:
```sh
rake redmine:plugins:migrate NAME=access_tickets
```
Before start using this plugin needs to set base parameters of access_tickets via URL /settings/plugin/access_tickets.
And then set the group leaders (Groupliders can view the access of workers consisting in the respective groups)
Groups of users, for which leaders are set to be available for selection in the "Availability" when editing a resource.
Users who are in the selected group when editing a resource, the resource will be able to choose when completing an access request.
###
RU:
###
Склонировать исходный код с GitHub:
```sh
cd <redmine_root_directory>/plugins
git clone https://github.com/iymaltsev/access_tickets.git access_tickets

```
Либо скачать [ZIP-архив](https://github.com/iymaltsev/access_tickets/archive/master.zip) и извлеч его содержимое в папку "access_tickets" (/var/lib/redmine/plugins/access_tickets).

И выполнить миграцию плагина:
```sh
rake redmine:plugins:migrate NAME=access_tickets
```
Перед началом использования данного плагина необходимо установить его базовые параметры через URL /settings/plugin/access_tickets
А затем установить руководителей групп (Руководители групп могут просматривать доступа работников, состоящих в соответствующих группах).
Группы пользователей, для который установлены руководители, будут доступны для выбора в меню "Доступен для групп" при редактировании ресурса.
Пользователи, состоящие в выбранных группах при редактировании ресурса, смогут выбрать данный ресурс при заполенении запроса доступа.

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
