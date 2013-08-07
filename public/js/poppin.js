(function (window) {
    var vendors = ['moz', 'webkit', 'o', 'ms'],
        i;
    
    for (i = 0; i < vendors.length && !window.requestAnimationFrame; i ++)
    {
        window.requestAnimationFrame = window[vendors[i] + 'RequestAnimationFrame'];
    }
    
}(this));

function Point(x,y,color){
  this.x = x;
  this.y = y;
  this.ox = x;
  this.oy = y;
  this.color = color;
};

var nodes = {
  //settings
  density: 4,
  drawdistance: 9,
  pushdistance: 200,
  pointradius: 1,
  color: {r:255,g:0,b:0,i:0},
  
  //set up
  animation: null,
  canvas: null,
  context: null,
  points: [],
  origins: [],
  mouse: {x:-1000,y:-1000,down:false},
  
  img : null,
  
  init: function(){
    this.canvas = document.getElementById( 'canvas' );
    this.context = canvas.getContext( '2d' );
    this.canvas.width = 600;
    this.canvas.height = 400;
    this.canvas.style.display = 'block';
    
    this.canvas.addEventListener('mousemove', this.mousemove, false);
    this.canvas.addEventListener('mousedown', this.mousedown, false);
    this.canvas.addEventListener('mouseup', this.mouseup, false);
    this.canvas.addEventListener('mouseout', this.mouseout, false);

    this.context.font =  "bold 200px 'Helvetica Neue'";
    this.context.fillStyle = 'white';		
    this.context.textAlign = 'center';
    this.context.fillText('MSG',this.canvas.width/2,this.canvas.height/2);
    
    this.img  = this.context.getImageData(0,0,this.canvas.width,this.canvas.height);
    
    this.checkpoints();
    
    //this.plotpoints();
    this.draw();
  },
  checkpoints: function(){
    var i, j;
    for(i = 0; i < this.canvas.height; i += this.density)
    {
      for(j = 0; j < this.canvas.width; j += this.density)
      {
        var pixelPosition = ( j + i * this.img.width ) * 4;
        if (this.img.data[pixelPosition + 3] === 0 ) {
          continue;
        }
        else
        {
          var color = 'rgba(' + this.img.data[pixelPosition] + ',' + this.img.data[pixelPosition + 1] + ',' + this.img.data[pixelPosition + 2] + ',1)';
        }
        this.points.push(new Point(j,i,color));
      }
    }
    
    for(i = 0; i < this.points.length; i++)
    {
      this.origins.push({ox:this.points[i].ox,oy:this.points[i].oy});
    }
  },
  spewpoints: function(){
    var i, currentpoint;
    for(i = 0; i < this.points.length; i++)
    {
      currentpoint = this.points[i];
      if(currentpoint.ox == this.origins[i].ox)
      {
        this.origins.push({ox:currentpoint.ox,oy:currentpoint.oy});
        
        currentpoint.ox = Math.random() * this.canvas.width;
        currentpoint.oy = Math.random() * this.canvas.height;
      }
      else
      {
        currentpoint.ox = this.origins[i].ox;
        currentpoint.oy = this.origins[i].oy;
      }
    }
  },
  plotpoints: function(){
    this.points = [];
    var i, max = 3, radius = 70;
    for(i = 0; i < max; i++)
    {
      this.points.push(new Point(200 + Math.cos(-Math.PI/2 + (Math.PI * 2) * i/max) * radius,200 + Math.sin(-Math.PI/2 + (Math.PI * 2) * i/max) * radius));
    }
  },
  updatepoints: function(){
    this.context.clearRect(0,0,this.canvas.width,this.canvas.height);
    
    var inc = 2;
    this.color.i += inc;
    if(this.color.i < 255)
    {
      this.color.g += inc;
    }
    else if(this.color.i < 510)
    {
      this.color.r -= inc;
    }
    else if(this.color.i < 765)
    {
      this.color.g -= inc;
      this.color.b += inc;
    }
    else if(this.color.i < 957)
    {
      this.color.g += inc;
    }
    else if(this.color.i < 1212)
    {
      if(this.color.g > 0) this.color.g -= inc;
      this.color.r += inc;
    }
    else if(this.color.i < 1467)
    {
      this.color.b -= inc;
    }
    else
    {
      this.color.i = 0;
    }
    
    var i, currentpoint, dx, dy, angle, mdistance;
    for(i = 0; i < this.points.length; i++)
    {
      currentpoint = this.points[i];
      
      dx = currentpoint.x - this.mouse.x;
      dy = currentpoint.y - this.mouse.y;
      angle = Math.atan2(dy,dx);
      mdistance = this.pushdistance/Math.sqrt(dx * dx + dy * dy); 
      // point moves away from mouse
      currentpoint.x += Math.cos(angle) * mdistance;
      currentpoint.y += Math.sin(angle) * mdistance;
      // point moves towards origin
      currentpoint.x += (currentpoint.ox - currentpoint.x) * .06;
      currentpoint.y += (currentpoint.oy - currentpoint.y) * .06;
    }
  },
  draw: function(){
    if(nodes.mouse.down) nodes.pushdistance += 10;
    nodes.updatepoints();
    nodes.drawpoints();
    //nodes.drawlines();
    this.animation = requestAnimationFrame(nodes.draw);
  },
  drawpoints: function(){
    var currentpoint, i;
    
    for(i = 0; i < this.points.length; i++)
    {
      currentpoint = this.points[i];
      this.context.beginPath();
      this.context.arc(currentpoint.x, currentpoint.y, this.pointradius, 0, 2 * Math.PI, false);
      
      //this.context.fillStyle = currentpoint.color;
      
      this.context.fillStyle = 'rgb(' + this.color.r + ',' + this.color.g + ',' + this.color.b +')';
      
      this.context.fill();
    }
  },
  drawlines: function(){
    var currentpoint, secondpoint, i, j, dx, dy, dist;
    for(i = 0; i < this.points.length; i++)
    {
      currentpoint = this.points[i];
      for(j = 0; j < this.points.length; j++)
      {
        secondpoint = this.points[j];
        if(secondpoint == currentpoint) continue;
        dx = secondpoint.x - currentpoint.x;
        dy = secondpoint.y - currentpoint.y;
        dist = Math.sqrt(dx * dx + dy * dy);
        if(dist <= this.drawdistance)
        {
          this.context.beginPath();
          this.context.moveTo(currentpoint.x,currentpoint.y);
          this.context.lineTo(secondpoint.x,secondpoint.y);
          this.context.lineWidth = 2;
          //this.context.lineWidth = this.pointradius * 2 - (this.pointradius * 2 * dist/this.drawdistance);
          this.context.strokeStyle = 'rgba(255,255,255,.5)';
          this.context.stroke();
        }
      }
    }
  },
  mousemove: function(e){
    nodes.mouse.x = e.offsetX;
    nodes.mouse.y = e.offsetY;
  },
  mousedown: function(){
    nodes.mouse.down = true;
    nodes.spewpoints();
  },
  mouseup: function(){
    nodes.mouse.down = false;
    nodes.pushdistance = 100;
  },
  mouseout: function(){
    nodes.mouse.x = -1000;
    nodes.mouse.y = -1000;
  }
};

nodes.init();