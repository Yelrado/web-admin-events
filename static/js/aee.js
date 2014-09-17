Processing.disableInit();
window.actions = {MOVE:0,LINE:1,RECT:2,CIRC:3,TEXT:4,TABLE:5,CHAIR:6,DELETE:7,SELECT:8,NONE:9,LOCKED:10};
window.event_data = null;
window.shared_data = null;
window.p = null;
window.onbeforeunload = function() {
	return msg_exit_warning;
}
window.aee = {
			
	init : function() {
		/* Inicia la aplicacion */
		$.ajax({
			url: url_event_data,
			data: {id_event : id_event},
			success: function(data) {
				event_data = JSON.parse(data);
			},
			async: false
		});
		$.ajax({
			url: url_shared_event_data,
			data: {id_event : id_event},
			success: function(data) {
				shared_data = JSON.parse(data);
			},
			async: false
		});
		
		// inicia processing.js
		Processing.loadSketchFromSources('sketch', [url_sketch]);
		
		aee.build_list();
		if(!is_owner) {
			setInterval("aee.get_event_data()",1000 * 24);
		}
		setInterval("aee.get_shared_data()",1000 * 12);
	},
	
	get_event_data : function(fail) {
		/* Recibe los datos del evento almacenados en el servidor. */
		$.ajax({
			url: url_event_data,
			data: {id_event : id_event},
			success: function(data) {
				event_data = JSON.parse(data);
				aee.build_list();
				p.buildElements();
				var action = event_data.locked ? actions.LOCKED : actions.NONE;
				p.setAction(action);
				p.size(event_data.width, event_data.height);
			}
		}).fail(aee.fail_function(fail));
	},
		
	set_event_data : function(fail) {
		/* Actualiza los datos del evento en el servidor. */
		var fail = aee.fail_function(fail);
		
		$.get( url_event_data, {
			id_event : id_event,
			data : JSON.stringify(event_data)
		}).fail(fail);
	},
	
	get_shared_data : function(fail) {
		/* Recibe los datos compartidos del evento almacenador en el servidor */
		$.ajax({
			url: url_shared_event_data,
			data: {id_event : id_event},
			success: function(data) {
				shared_data = JSON.parse(data);
				aee.build_list();
			}
		}).fail(aee.fail_function(fail));
	},
	
	set_a_shared_data : function(variable, id, value, fail) {
		/* Actualiza sólo un elemento compartido, lo almacena en el servidor */
		$.ajax({
			url: url_shared_event_data,
			data: {
				id_event : id_event,
				variable : variable,
				id_object : id,
				value : value
			}
		}).fail(aee.fail_function(fail));
	},
	
	rename_event : function(new_name) {
		/* Renombra el evento */
		$.get( url_rename_event, {
			id_event : id_event,
			new_name : new_name
		}).done(function(json){
			event_data.name = new_name;
			$('#eventName').html(new_name);
		}).fail(function(){
			aee.flash_message(msg_conection_error);
		});
	},
	
	print : function() {
		/* Crea un JSON con la lista y la imagen y abre
		 * una nueva pestaña en /print */
		window.image = document.getElementById('sketch').toDataURL();
		var win = window.open(url_print_event, '_blank');
		win.focus();
		win.print();
	},
	
	save : function() {
		/* Guarda los datos en data_event y ejecuta los funciones 
		 * necesarias para la integridad de datos. */
		aee.set_event_data();
		aee.flash_message(msg_saved);
	},
	
	create_category : function() {
		/* Crea una categoría nueva y la almacena en data_event.
		 * Recibe elnombre de la categoría y el color en hexadecimal. */
		var name = $('input[id="categoryNewName"]').val();
		var color = $('input[id="categoryColor"]').val();
		if (name == "" || color == "") {
			aee.flash_message(msg_fill_form);
			return false;
		}
		
		var key = "category" + event_data.autoincrement++;
		event_data.list.category[key] = { name : name, color : color, elements : {}};
		aee.build_select();
		$('input[id="categoryNewName"]').val("");
	},
	
	create_list_element : function() {
		/* Crea un elemento de la lista y la almacena en 
		 * data_event. Recibe el nombre, el id de la categoría,
		 * el color en hexadecimal y el tipo de elemento
		 * (individual o grupal).*/
		var name = $('input[id="elementNewName"]').val();
		var category_id = $('#selectCategories').val();
		var color = $('input[id="elementColor"]').val();
		var type = $('input[name="optionsRadios"]:checked').val();
		
		if (name == "" || category_id == "0" || color == "" || type == undefined) {
			aee.flash_message(msg_fill_form);
			return false;
		}
		
		var key = "listElem" + event_data.autoincrement++;
		
		event_data.list.category[category_id].elements[key] = {
			name : name,
			color : color,
			type : type,
			links : []
		}
		aee.build_list();
		$('input[id="elementNewName"]').val("");
		$('#selectCategories').val(category_id);
		$('#collapse'+category_id).collapse('show');
	},
	
	delete_category : function(category_id) {
		/* Elimina la categoría y todo su contenido.
		 * Confirmar antes de ejecutar.*/
		if(confirm(msg_confirm_delete)) {
			delete event_data.list.category[category_id];
			aee.build_list();
			p.buildElements();
		}
	},
	
	delete_list_element : function(element_list_id) {
		/* Elimina un elemento de la lista por su id.
		 * Confirmar antes de ejecutar. */
		if(confirm(msg_confirm_delete)) {
			for(var k in event_data.list.category) {
				if(element_list_id in event_data.list.category[k].elements) {
					delete event_data.list.category[k].elements[element_list_id];
					aee.build_list();
					buildElements();
					break;
				}
			}
		}
	},
	 
	search_unlinked : function() {
		/* Busca los elementos del escenario que no tiene ninguna
		 * relación dentro de la lista y devuelve un arreglo con
		 * los resultados con la estructura de una categoria. */
		var unlinkeds = {};
		for(var k in event_data.stage.elements) {
			if(event_data.stage.elements[k].linkeable == true && !aee.has_links(k)) {
				unlinkeds[k] = {
					name : k,
					color : "#fff",
					type : "group",
					links : []
				};
			}
		}
		return { name : msg_category_unlinked, color : "#fff", elements : unlinkeds};
	},
	
	set_list_element_assistance : function(list_element_id, value) {
		/*Actualiza el valor de shared_data y hace la 
		 * llamada al servidor para distribuir los nuevos valores.*/
		shared_data.assistance[list_element_id] = value;
		aee.set_a_shared_data("assistance", list_element_id, value);
	},
	
	build_list : function() {
		/* Crea la lista con los datos del JSON */
		if ($('input[id="prependedInput"]').val().length > 0) {
			return;
		}
		
		var collapseds = []; // guarda el estado de las tabs abiertas
		$.each($('.in'), function(i, data) {
			collapseds.push($(data).attr('id'));
		});
		$('#listTree').empty();
		
		var libres = aee.search_unlinked();
		if(Object.keys(libres.elements).length > 0) {
			aee.add_ui_category(libres, "unlinkeds");
		}
		
		for(var key in event_data.list.category) {
			aee.add_ui_category(event_data.list.category[key], key);
		}
		aee.build_select();
		$('input[id="stageWidth"]').val(event_data.width);
		$('input[id="stageHeight"]').val(event_data.height);
		// restaura las tabs abiertas
		for(var c in collapseds) {
			$('#'+collapseds[c]).collapse('show');
		}
	},
	
	search : function() {
		/* Busca las coincidencias, crea una estructura similar
		 * a event_data y crea la lista. Si no hay nada que buscar
		 * genera la lista normal.
		 */
		$('#listTree').empty();
		var strSearch = $('input[id="prependedInput"]').val().toLowerCase();
		if(strSearch.length == 0) {
			aee.build_list();
			return;
		}
		var results = { name : msg_results, color : "#fff", elements : {}};
		for(var key_cat in event_data.list.category) {
			for(var key in event_data.list.category[key_cat].elements) {
				if(event_data.list.category[key_cat].elements[key].name.toLowerCase().indexOf(strSearch) > -1) {
					results.elements[key] = event_data.list.category[key_cat].elements[key];
				}
			}
		}
		aee.add_ui_category(results, "searchResults");
		$("#collapsesearchResults").collapse('show');
	},
	
	update_size_stage : function() {
		/* Obtiene las medidas de los input y actualiza el tamaño */
		var width = $('input[id="stageWidth"]').val();
		var height = $('input[id="stageHeight"]').val();
		p.setSize(width, height);
	},
	
	build_select : function() {
		/* Crea las opciones de las categorias */
		var myDiv = $('div#categories');
		myDiv.empty();
		//Create and append select list
		var selectList = document.createElement("select");
		selectList.setAttribute("id", "selectCategories");
		myDiv.append(selectList);
		
		//Create and append the options
	    var option = document.createElement("option");
	    option.setAttribute("value", "0");
	    option.text = str_select;
	    selectList.appendChild(option);
		for (var key in event_data.list.category) {
		    var option = document.createElement("option");
		    option.setAttribute("value", key);
		    option.text = event_data.list.category[key].name;
		    selectList.appendChild(option);
		}
	},
	
	add_ui_category : function(category, id) {
	  var divCategory = document.createElement('div');
	  var parentAccordion = 'listTree';
	  $(divCategory).addClass('accordion-group');
	  var html = '<div class="accordion-heading text-center">';
	  html += '<ul class="inline">';
	  html += '<li><div style="width: 12px; height: 12px; background: '+category.color+';"></div></li>';
	  html += '<li><a class="accordion-toggle" data-toggle="collapse" data-parent="#'+parentAccordion+'" href="#collapse'+id+'">' + category.name + '</a></li>';
	  if(is_owner && id != "unlinkeds" && id != "searchResults") {
	    html += '<li class="pull-right"><i class="icon-remove" onclick="aee.delete_category(\''+id+'\')" title="'+str_delete_category+'"></i></li>';
	  }
	  html += '</ul>';
	  html += '</div>';
	  html += '<div id="collapse'+id+'" class="accordion-body collapse">';
	  html += '<div class="accordion-inner">';
	  for(var key in category.elements){
		var elmntLst = '<ul class="inline">';
			elmntLst += '<li><div style="width: 12px; height: 12px; background: '+category.elements[key].color+';" onclick="aee.hightlight([\''+key+'\'])"></div></li>';
			elmntLst += '<li>'+ category.elements[key].name + '</li>';
			if (is_owner && id != "unlinkeds") {
			  elmntLst += '<li class="pull-right"><i class="icon-remove" onclick="aee.delete_list_element(\''+key+'\')" title="'+str_delete_element+'"></i></li>';
			  elmntLst += '<li class="pull-right"><i class="icon-cog" onclick="p.linkListToStage(event_data.list.category[\''+id+'\'].elements[\''+key+'\'])" title="'+str_make_link+'"></i></li>';
			}
			if (category.elements[key].type == "individual") {
			  /* checkbox de asistencia */
			  var checked;
			  if(key in shared_data.assistance && shared_data.assistance[key] == "true") {
				checked = "checked";
			  } else {
				checked = "";
			  }
			  elmntLst += '<li class="pull-right"><input type="checkbox" onclick="aee.set_list_element_assistance(\''+key+'\', this.checked)" name="'+key+'" value="'+key+'" title="'+str_assistance+'" '+checked+'></li>';
			}
		elmntLst += '</ul>';
		html += elmntLst;
	  }
	  html += '</div></div></div>';
	  divCategory.innerHTML = html;
	  $('#listTree').append(divCategory);
	},
	
	hightlight : function(list_element_id) {
		/* resalta los elementos relacionados con la lista */
		for(var k in event_data.list.category) {
			if(list_element_id in event_data.list.category[k].elements) {
				p.setHightlightedElements(event_data.list.category[k].elements[list_element_id].links);
				break;
			}
		}
	},
	
	flash_message : function(msg) {
		/* Muestra un mensaje durante un segundo */
		$(".flash").html(msg).slideDown().delay(1000).slideUp();
	},
	
	fail_function : function(f) {
		/* funcion por default para conexiones */
		if(f === undefined) {
			return function() {
				aee.flash_message(msg_conection_error);
			}
		}
		return f;
	},
	
	activate_action : function(btn, action) {
		/* Activa una funcion del escenario y cambia los botones
		 * inhabilitando el seleccionado */
		if(action == actions.LOCKED) {
			if(actions.LOCKED != p.getActualAction()) {
				$('.btn-action').prop("disabled", true);
				$(btn).prop("disabled", false);
				event_data.locked = true;
			} else {
				$('.btn-action').prop("disabled", false);
				$(btn).prop("disabled", false);
				var action = actions.NONE;
				event_data.locked = false;
			}
		} else {
			$('.btn-action').prop("disabled", false);
			$(btn).prop("disabled", true);
		}
		p.setAction(action);
	},
	
	delete_key : function(variable, key) {
		delete variable[key];
	},
	
	has_links : function(stage_element_id) {
		/* Busca si tiene un elemento del escenario tiene link con la lista
		 */
		var has = false;
		var d = event_data.list.category;
		$.each(d, function(ka,va){
		  $.each(va.elements,function(kb,vb){
			$.each(vb.links,function(i,vc){
			  if(vc == stage_element_id) {
				has = true;
			    return false;
			  }
			});
			if(has) {
			  return false;
			}
		  });
		  if(has) {
			return false;
		  }
		});
		return has;
	},
		
	search_elemstage_links : function(element, id) {
		  if(!element.linkeable) return [[],[]];
		  var categoryColors = [];
		  var elementColors = [];
		  for(var k_category in event_data.list.category) {
			var cat = event_data.list.category[k_category];
			for(var k_element in cat.elements) {
			  var ele = cat.elements[k_element];
			  for(var k_link in ele.links) {
				var link = ele.links[k_link];
				if(link == id) {
				  categoryColors.push(p.unhex("FF"+cat.color.replace('#','')));
				  elementColors.push(p.unhex("FF"+ele.color.replace('#','')));
				}
			  }
			} 
		  }
		  return {categoryColors:categoryColors,elementColors:elementColors};
	},
	
	link_listelement_to_stageelement : function(listElement, selected) {
		/* Hace un enlace del elemento de la lista hacia el escenario */
		listElement.links.push(selected);
		aee.build_list();
	}

};

