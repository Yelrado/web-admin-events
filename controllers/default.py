# -*- coding: utf-8 -*-
# this file is released under public domain and you can use without limitations

#########################################################################
## This is a sample controller
## - index is the default action of any application
## - user is required for authentication and authorization
## - download is for downloading files uploaded in the db (does streaming)
## - call exposes all registered services (none by default)
#########################################################################
KEY = 'miclaveparafirmarurls';

def index():
    """
    Pantalla de bienvenida estatica,
    sólo muestra un enlace hacia el manejador
    """
    return dict()


@auth.requires_login()
def manager():
	"""
	Permite crear eventos nuevos, ver/copiar los creados por otros
	y editar los que se fueron creados por el usuario actual
	"""
	form = FORM(T('New Event'),
				INPUT(_name='name', requires=IS_NOT_EMPTY()),
				INPUT(_type='submit'))
	if form.accepts(request, session):
		# Generar el nuevo evento vacío
		name = form.vars.name
		owner_event = auth.user_id
		event_data = base_json_event_data.replace('"name":null', '"name":"'+name+'"')
		shared_data = base_json_shared_data
		id_event = db.events.insert(name=name, owner_event=owner_event,
									json_event_data=event_data,
									json_shared_data=shared_data)
		if id_event:
			redirect(URL('default', 'event',
						 args=[db.events[id_event].slug]))
		else:
			response.flash = T('The new event can\'t be created')
	elif form.errors:
		response.flash = T('The form has errors')	
	if request.vars.id_event:
		if request.vars.operation == 'copy':
			if not URL.verify(request, hmac_key=KEY): # verifica que la accion sea legitima
				raise HTTP(403)
			shared_data = base_json_shared_data
			row = db.events[request.vars.id_event]
			event_data = row.json_event_data
			name = row.name + T('(copy)')
			if db.events.insert(name=name, owner_event=auth.user_id,
							 json_event_data=event_data,
							 json_shared_data=shared_data):
				response.flash = T('Event copied')
			else:
				response.flash = T('It can\'t be copied')
		elif request.vars.operation == 'delete':
			if not URL.verify(request, hmac_key=KEY): # verifica que la accion sea legitima
				raise HTTP(403)
			if db.events[request.vars.id_event] \
			   and db.events[request.vars.id_event].owner_event == auth.user_id:
				del db.events[request.vars.id_event]
				response.flash = T('Event deleted')
			else:
				response.flash = T('You do not have permission to do that')
	
	events = db(db.events).select(db.events.ALL)
	
	return dict(events=events,form=form,key=KEY)


@auth.requires_login()
def event():
	"""
	Es la página principal de la aplicación, tiene dos modos que
	dependen de los privilegios del usuario, si el usuario creo este
	evento se abre en modo edición de lo contrario en modo lectura,
	a excepción de los datos compartidos (actualmente sólo de
	asistencia). El parametro será el nombre del evento como slug,
	para abrir directamente la página.
	Es requerido un usuario logueado.
	"""
	if not request.args[0]:
		redirect(URL('default', 'manager'))
	
	event = db(db.events.slug == request.args[0]).select(db.events.ALL).first()
	if not event:
		event = db.events[request.args[0]]
		if event:
			redirect(URL('default', 'event', args=[event.slug]))
		else:
			raise HTTP(404, T('Event not found'))
		
	is_owner = event.owner_event == auth.user_id
	
	return dict(event=event, is_owner=is_owner)


def print_event():
	"""
	Genera una vista apta para impresión con los datos de la ventana
	padre (event).
	"""
	return dict()


@auth.requires_login()
def event_data():
	"""
	Es un webservice de JSON para subir y recoger datos sobre
	el evento. El único que puede subir datos es el creador del
	evento, los usuarios registrados son los que pueden leer
	los datos. El parametro id_event devuelve los datos JSON
	de ese evento, si se usa el metodo post/get data se pueden subir
	datos que sobreescribiran los actuales (sólo el creador puede
	hacer esto), devuelve true si los datos fueron actualizados
	con éxito, false si hubo error.
	"""
	if request.vars.id_event:
		if request.vars.data:
			if db.events[request.vars.id_event].owner_event == auth.user_id:
				# Actualizar los valores
				db.events[request.vars.id_event] = dict(json_event_data=request.vars.data)
				return 'true'
			else:
				raise HTTP(500, 'false')
		else:
			# Devolver json
			return db.events[request.vars.id_event].json_event_data
	else:
		raise HTTP(400, 'false')


@auth.requires_login()
def shared_event_data():
	"""
	Es un webservice de JSON, en este caso cualquiera registrado
	puede modificar los datos del evento. El primer parametro
	indica sobre que evento se quiere trabajar, los parametros
	get/post son variable, id_object y value. Variable indica a que objeto
	json hijo se va a aplicar el cambio, el id a que hijo de la
	variable, finalmente el valor indica el nuevo valor, de no
	existir se genera y si existe es reemplazado. Si ningún parametro
	es dado devuelve todo el objeto JSON shared_data.
	Es necesario estar logueado.
	"""
	if request.vars.id_event:
		if request.vars.variable \
		   and request.vars.id_object and request.vars.value:
			json_shared_data = db.events[request.vars.id_event].json_shared_data
			import json
			python_shared_data = json.loads(json_shared_data)
			python_shared_data[request.vars.variable][request.vars.id_object] = request.vars.value
			json_shared_data = json.dumps(python_shared_data)
			# Actualizar el json en la base de datos
			db.events[request.vars.id_event] = dict(json_shared_data=json_shared_data)
			return 'true'
		else:
			return db.events[request.vars.id_event].json_shared_data
	else:
		raise (400, 'false')

@auth.requires_login()
def rename_event():
	""" Renombrar el evento """
	if request.vars.id_event and request.vars.new_name:
		if db.events[request.vars.id_event].owner_event == auth.user_id:
			db.events[request.vars.id_event] = dict(name=request.vars.new_name)
		else:
			raise (500, 'false')
	else:
		raise (400, 'false')


def user():
    """
    exposes:
    http://..../[app]/default/user/login
    http://..../[app]/default/user/logout
    http://..../[app]/default/user/register
    http://..../[app]/default/user/profile
    http://..../[app]/default/user/retrieve_password
    http://..../[app]/default/user/change_password
    http://..../[app]/default/user/manage_users (requires membership in
    use @auth.requires_login()
        @auth.requires_membership('group name')
        @auth.requires_permission('read','table name',record_id)
    to decorate functions that need access control
    """
    return dict(form=auth())

@cache.action()
def download():
    """
    allows downloading of uploaded files
    http://..../[app]/default/download/[filename]
    """
    return response.download(request, db)

