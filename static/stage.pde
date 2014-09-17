/**
 * Stage for Administrador de Escenario para Eventos
 * Manage all visual options, shapes and tools for make a
 * map of any stage.
 */

ArrayList elements; // store the elements
int tam; // number of elements
int action; // set an action
var listElement; // Element of the list that would be linked
int LINE=0,RECT=1,CIRC=2,TABLE=3,CHAIR=4,TEXT=5; //class of the shape
// a bunch of colours
color orange = color(255,77,0);
color blue = color(0,180,255);
color neon = color(127,255,36);
color gold = color(240,240,0);
// variables for bounding shapes
int boundX, boundY;
boolean bounding = false;
// images
PImage img_chair;
PImage img_table;
// variables for texts
PFont f;
float ascent, descent;
/**
 * Initial setup
 * It loads svg images, initials global variables, sets size,
 * sets default configurations and build elements from json data
 */
void setup() {
  p = Processing.instances[0]; // save my instance in a global variable
  action = event_data.locked ? actions.LOCKED : actions.NONE; // default action
  if(action == actions.LOCKED) {
	//trick to disable buttons
	action = actions.NONE;
	aee.activate_action('#btnLocked', actions.LOCKED);
  }
  img_chair = requestImage(url_chair); // it loads chair shape
  img_table = requestImage(url_table); // it loads table shape
  // always use mode CORNERS
  rectMode(CORNERS);
  ellipseMode(CORNERS);
  shapeMode(CORNERS);
  imageMode(CORNERS);
  // set standard font
  f = createFont("Arial",16,true);
  textAlign(LEFT);
  textFont(f);
  textSize(16);
  ascent = textAscent();
  descent = textDescent(); 
  // create the initial build
  size(event_data.width, event_data.height); // set size
  buildElements();
}

/**
 * Draw loop
 * It draws a grill and all shapes, also sets de current action and
 * triggers its functions.
 */
void draw() {
  grill();
  switch(action) {
    case actions.LOCKED:
    case actions.NONE:
      cursor(ARROW);
      break;
    case actions.MOVE:
      cursor(ARROW);
      for (int i = 0; i < tam; i++) {
        ((Shape)elements.get(i)).fRollover(mouseX,mouseY);
        ((Shape)elements.get(i)).drag(mouseX,mouseY);
      }
      break;
    case actions.DELETE:
      cursor(ARROW);
      for (int i = 0; i < tam; i++) {
        ((Shape)elements.get(i)).fRollover(mouseX,mouseY);
      }
      break;
    case actions.SELECT:
      cursor(ARROW);
      for (int i = 0; i < tam; i++) {
        ((Shape)elements.get(i)).fRollover(mouseX,mouseY);
      }
      break;
    case actions.LINE:
    case actions.RECT:
    case actions.CIRC:
    case actions.TABLE:
    case actions.CHAIR:
      cursor(CROSS)
      drawBound(mouseX,mouseY);
      break;
    case actions.TEXT:
        cursor(TEXT);
        break;
  }
  for (int i = 0; i < tam; i++) {
    // always draw shapes
    ((Shape)elements.get(i)).display();
  }

}

/**
 * Change the current action
 */
void setAction(int _action) {
  action = _action;
}

/**
 * Returns actual action
 */
int getActualAction() {
	return action;
}
/**
 * Actions for mouse pressed
 */
void mousePressed() {
  switch(action) {
  case actions.MOVE:
    for (int i = 0; i < tam; i++) {
    ((Shape)elements.get(i)).clicked(mouseX,mouseY);
    }
    break;
  case actions.DELETE:
    for (int i = 0; i < tam; i++) {
        ((Shape)elements.get(i)).delete(mouseX,mouseY);
    }
    aee.build_list();
    break;
  case actions.SELECT:
    String selected = null;
    for (int i = 0; i < tam; i++) {
      if (((Shape)elements.get(i)).isSelected(mouseX,mouseY)) {
        selected = ((Shape)elements.get(i)).name;
        break;
      }
    }
    
    if (selected != null) {
      aee.link_listelement_to_stageelement(listElement, selected);
      buildElements(); // upgrade shapes
    } else {
	  aee.flash_message(msg_nothing_select);
    }
    action = actions.NONE;
    break;
  case actions.LINE:
  case actions.RECT:
  case actions.CIRC:
  case actions.TABLE:
  case actions.CHAIR:
    // Start drawing bounds
    boundX = mouseX;
    boundY = mouseY;
    bounding = true;
    break;
  case actions.TEXT:
    boundX = mouseX; // little hack, I guess
    boundY = mouseY;
    // Inmediatly make text shape
    String stext = prompt(msg_enter_text);
    String key = createShape(TEXT, false);
    event_data.stage.elements[key].opts.text = stext;
    buildElements();
    break;
  }
}

/**
 * Actions for mouse released
 */
void mouseReleased() {
  switch(action) {
  case actions.MOVE:
    for (int i = 0; i < tam; i++) {
    ((Shape)elements.get(i)).stopDragging();
    }
    break;
  case actions.LINE:
    String key = createShape(LINE, false);
    buildElements(); // upgrade elements
    break;
  case actions.RECT:
    String key = createShape(RECT, false);
    buildElements();
    break;
  case actions.CIRC:
    String key = createShape(CIRC, false);
    buildElements();
    break;
  case actions.TABLE:
    String key = createShape(TABLE, true);
    // event_data.stage.elements[key].opts['foo'] = "bar";
    buildElements();
    aee.build_list(); // update list
    $('#collapseunlinkeds').collapse('show');
    break;
  case actions.CHAIR:
    String key = createShape(CHAIR, true);
    buildElements();
    aee.build_list(); // update list
    $('#collapseunlinkeds').collapse('show');
    break;
  case actions.LOCKED:
    break;
  }
}

/**
 * A generic function to make a json structure for a new shape
 * developed for mousePressed()
 * buildElements() is required after this to reflect changes
 */
String createShape(String class_, boolean linkeable) {
  bounding = false;
  int x1=boundX; int y1=boundY;
  int x2=mouseX; int y2=mouseY;
  int id = event_data.autoincrement++; // it reads first then increase
  String name = "stageElem"+id;
  var element = {class_:class_, linkeable:linkeable,x1:x1,y1:y1,x2:x2,y2:y2,opts:{a:0}};
  event_data.stage.elements[name] = element;
  
  return name;
}

/**
 * Start the selection to asign a element to a list
 */
void linkListToStage(String element) {
  listElement = element;
  action = actions.SELECT;
}

/**
 * Mark shapes highlighted as the argument says
 */
void setHightlightedElements(String[] ids) {
  for (int i = 0; i < tam; i++) {
    ((Shape)elements.get(i)).hightlighted = false;
  }
  for (int i = 0; i < tam; i++) {
	if(((Shape)elements.get(i)).linkeable) {
      for (int j = 0; j < ids.length; j++) {
        if(((Shape)elements.get(i)).name == ids[j]) {
          ((Shape)elements.get(i)).hightlighted = true;
          break;
	    }
	  }
    }
  }
}

/**
 * Change the size of the canvas
 */
void setSize(int width, int height) {
  size(width, height);
  event_data.width = width;
  event_data.height = height;
}

/**
 * Build the elements of the stage from the JSON to show it in the canvas
 */
void buildElements() {
  int nTam = Object.keys(event_data.stage.elements).length; // get length
  ArrayList nElements = new ArrayList(nTam); // create a empty arraylist of nElements
  for (var key in event_data.stage.elements) {
    String name = key; // access the key and store the string key
    var e = event_data.stage.elements[key]; // I already have access to the element
    var colours = aee.search_elemstage_links(e, key); // search for links
    // Make the shape with the data and add to the arraylist
    Shape new_shape;
    switch(e.class_) {
      case LINE:
        new_shape = new Line(name,e.x1,e.y1,e.x2,e.y2);
        break;
      case RECT:
        new_shape = new Rect(name,e.x1,e.y1,e.x2,e.y2);
        break;
      case CIRC:
        new_shape = new Circ(name,e.x1,e.y1,e.x2,e.y2);
        break;
      case TABLE:
        new_shape = new Table(name,e.x1,e.y1,e.x2,e.y2,colours.categoryColors,colours.elementColors);
        break;
      case CHAIR:
        new_shape = new Chair(name,e.x1,e.y1,e.x2,e.y2,colours.categoryColors,colours.elementColors);
        break;
      case TEXT:
        new_shape = new Text(name,e.opts.text,e.x1,e.y1);
        break;
    }
    nElements.add(new_shape);
  }
  cursor(WAIT);
  noLoop();
  elements = null;
  elements = nElements;
  tam = nTam;
  setTimeout(function(){loop(); cursor(ARROW);}, 100);
}

/**
 * Draw a grill for a better experience
 */
void grill() {
  background(255);
  if (action != actions.LOCKED) {
    strokeWeight(1);
    for (int i=20; i < width || i < height; i+=20) {
      if (i % 100 == 0) {
        stroke(128);
      } else {
        stroke(200);
    }
    line(i,0,i,height); // vertical
    line(0,i,width,i); // horizontal
    }
  }
}

/**
 * Draw bounds in real time (trigger by draw())
 */
void drawBound(x,y) {
  if(bounding) {
    stroke(orange);
    noFill();
    rect(boundX,boundY,x,y);
  }
}

/**
 * Click and Drag an object
 * Daniel Shiffman 
 * Edited by Angel Alvarado
 * A class for a draggable thing
 */

class Shape {
  boolean dragging = false; // Is the object being dragged?
  boolean rollover = false; // Is the mouse over the ellipse?
  boolean deleted = false; // Is deleted?
  String name; // id of the object
  boolean linkeable; // Is the object linkeable with the list?
  boolean hightlighted = false; // is the object hightlighted?
  color[] background;
  color[] foreground;
  
  float x1,y1,x2,y2;       // Location and size
  float offsetX, offsetY;  // Mouseclick offset
  float r_width, r_height; // real width and height

  /**
   * General constructor
   */
  Shape(String _name, boolean _linkeable,
        float x1, float y1, float x2, float y2,
        color[] colorCategories, color[] colorElement) {
    name = _name;
    linkeable = _linkeable;
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    offsetX = 0;
    offsetY = 0;
    r_width = x2-x1;
    r_height = y2-y1;
    background = colorCategories;
    foreground = colorElement;
  }

  /**
   * Constructor for a no-linkeable shape
   */
  Shape(String _name, float x1, float y1,
        float x2, float y2) {
  this(_name,false,x1,y1,x2,y2,null,null);
  }

  /** Method to display */
  void display() {
    if (deleted) {
      return;
    }
  //~ void display() {
  //~ super.display();
  //~ strokeWeight(3);
    //~ noFill();
    //~ if (dragging) {
    //~ stroke(0,50);
  //~ } else if (rollover) {
    //~ fill(orange);
  //~ } else {
    //~ stroke(0);
  //~ }
    //~ rect(x,y,w,h);
    //~ }
  }
  
  /**
   * Draw a background and foreground with Element and Category colours
   * given a scale
   */
  void base(float scale_) {
    if(linkeable) {
      noStroke();
      if(background != null) {
        float sca = scale_;
        int addX = ((y2-y1)*sca)-(y2-y1);
        int addY = ((x2-x1)*sca)-(x2-x1);
    
        float salt = (x2-x1+addX*2) / background.length;
        int wa = x1;
        for(int i=0; i < background.length; i++) {
          fill(background[i]);
          int a1 = wa-addX, b1 = y1-addY;
          int a2 = wa-addX + salt, b2 = y2+addY;
          rect(a1,b1,a2,b2);
          wa += salt;
        }
      }
      if(foreground != null) {
        float salt = (x2-x1) / foreground.length;
        int wa = x1;
        for(int i=0; i < foreground.length; i++) {
          fill(foreground[i]);
          int a1 = wa, b1 = y1;
          int a2 = wa + salt, b2 = y2;
          rect(a1,b1,a2,b2);
          wa += salt;
        }
      }
    }
  }
  
  /**
   * is in the bounds?
   */
  boolean inBounds(int mx, int my) {
	  return (mx > x1 && mx < x2 && my > y1 && my < y2);
  }
  
  /**
   * Delete this shape
   */
  void delete(int mx, int my) {
    if (inBounds(mx,my)) {
      deleted = true;
      aee.delete_key(event_data.stage.elements, name);
      buildElements(); // re-build canvas
      aee.activate_action('.no-one-button', actions.NONE);
    }
  }

  /**
   * Is a point inside the rectangle (for click)?
   */
  void clicked(int mx, int my) {
    if (inBounds(mx,my)) {
      dragging = true;
      cursor(MOVE);
      // If so, keep track of relative location of click to corner of rectangle
      offsetX = x1-mx;
      offsetY = y1-my;
      r_width = x2-x1;
      r_height = y2-y1;
    }
  }
  
  /**
   * was it selected?
   */
  boolean isSelected(int mx, int my) {
	if (linkeable && inBounds(mx,my)) {
      return true;
	}
	return false;
  }
  
  /** Is a point inside the rectangle (for rollover) */
  void fRollover(int mx, int my) {
    if (inBounds(mx,my)) {
      if (!mousePressed) cursor(HAND);
      rollover = true;
    } else {
      rollover = false;
    }
  }

  /** Stop dragging */
  void stopDragging() {
    dragging = false;
    cursor(HAND);
    event_data.stage.elements[name].x1 = x1;
    event_data.stage.elements[name].y1 = y1;
    event_data.stage.elements[name].x2 = x2;
    event_data.stage.elements[name].y2 = y2;
  }
  
  /** Drag the rectangle */
  void drag(int mx, int my) {
    if (dragging) {
      x1 = mx + offsetX;
      y1 = my + offsetY;
      x2 = x1 + r_width;
      y2 = y1 + r_height;
      cursor(MOVE);
    }
  }

}

/**
 * Class for a Line
 */
class Line extends Shape {
  
  Line(String _name, float x1, float y1,
         float x2, float y2) {
    super(_name,x1,y1,x2,y2);
  }
  
  void display() {
    super.display();
    strokeWeight(3);
    if (dragging) {
      stroke(0,50);
    } else if (rollover) {
      stroke(orange);
    } else {
      stroke(0);
    }
    line(x1,y1,x2,y2);
  }
}

/**
 * Class for a Rectangle
 */
class Rect extends Shape {

  Rect(String _name, float x1, float y1,
         float x2, float y2) {
    super(_name,x1,y1,x2,y2);
  }
    
  void display() {
    super.display();
    strokeWeight(3);
    noFill();
    if (dragging) {
    stroke(0,50);
    } else if (rollover) {
      fill(orange);
    } else {
      stroke(0);
    }
    rect(x1,y1,x2,y2);
  }
}

/**
 * Class for a Circule
 */
class Circ extends Shape {

  Circ(String _name, float x1, float y1,
         float x2, float y2) {
    super(_name,x1,y1,x2,y2);
  }
  
  void display() {
    super.display();
    strokeWeight(3);
    noFill();
    if (dragging) {
      stroke(0,50);
    } else if (rollover) {
      fill(orange);
    } else {
      stroke(0);
    }
      ellipse(x1,y1,x2,y2);
  }
}

/**
 * Class for a Table
 */
class Table extends Shape {

  Table(String _name, float x1, float y1, float x2, float y2,
        color[] colorCategories, color[] colorElement) {
    super(_name, true, x1,y1,x2,y2,colorCategories,colorElement);
  }

  void display() {
    super.display();
    noStroke();
    if (dragging) {
      fill(blue,50);
      rect(x1,y1,x2,y2);
    } else if (rollover) {
      fill(orange);
      rect(x1,y1,x2,y2);
    } else if(hightlighted) {
	  fill(gold);
      rect(x1,y1,x2,y2);
	} else {
      base(1.2);
    }
    if (img_table.width == 0) {
		rect(x1,y1,x2,y2);
	} else {
      image(img_table,x1,y1,x2,y2);
    }
  }
}

/**
 * Class for a Chair
 */
class Chair extends Shape {

  Chair(String _name, float x1, float y1, float x2, float y2,
        color[] colorCategories, color[] colorElement) {
    super(_name, true, x1,y1,x2,y2,colorCategories,colorElement);
  }
    
  void display() {
    super.display();
    noStroke();
    if (dragging) {
      fill(blue,50);
      rect(x1,y1,x2,y2);
    } else if (rollover) {
      fill(orange);
      rect(x1,y1,x2,y2);
    } else if(hightlighted) {
	  fill(gold);
      rect(x1,y1,x2,y2);
	} else {
      base(1.2);
    }
    if (img_chair.width == 0) {
		rect(x1,y1,x2,y2);
	} else {
      image(img_chair,x1,y1,x2,y2);
    }
  }
}

/**
 * Class for text
 */
class Text extends Shape {
  String stext;
  int px, py;

  Text(String _name, String _text, float px_, float py_) {
    px = px_;
    py = py_;
    stext = _text;
    x1 = px;
    y1 = py - ascent;
    x2 = px + textWidth(stext);
    y2 = py + descent;
    name = _name;
  }
    
    void display() {
      super.display();
      if (dragging) {
        fill(blue,50);
      } else if (rollover) {
        fill(orange);
      } else {
        fill(0);
      }
      text(stext,px,py);
    }
  
  void drag(int mx, int my) {
    if(dragging) {
      px = mx + offsetX;
      py = my + offsetY;
        
      x1 = px;
      y1 = py - ascent;
      x2 = px + textWidth(stext);
      y2 = py + descent;
    }
  }
}
