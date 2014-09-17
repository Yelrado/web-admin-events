# -*- coding: utf-8 -*-
# this file is released under public domain and you can use without limitations

#########################################################################
## Customize your APP title, subtitle and menus here
#########################################################################

response.logo = A(B('A',SPAN('E'),'E'),_class="brand")
response.title = 'Administrador de Escenario para Eventos'
response.subtitle = ''

## read more at http://dev.w3.org/html5/markup/meta.name.html
response.meta.author = 'Angel Alvarado <alvaradoangel57@gmail.com>'
response.meta.keywords = 'administrador, escenario, eventos, aee'
response.meta.generator = 'Web2py Web Framework'

## your http://google.com/analytics id
response.google_analytics_id = None

#########################################################################
## this is the main application menu add/remove items as required
#########################################################################

response.menu = [
    (T('Home'), False, URL('default', 'index'), []),
    (T('Manager'), True, URL('default', 'manager'), [])
]

if "auth" in locals(): auth.wikimenu()
