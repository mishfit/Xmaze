//
//  MyDrawingView.m
//  MyDrawingApp
//
//  Created by joel johnson on 6/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MyDrawingView.h"


@implementation MyDrawingView

@synthesize currentColor;
@synthesize fillColor;

#define SQ_SIZE         5

#define MAX_MAZE_SIZE_X	205
#define MAX_MAZE_SIZE_Y	205

#define MOVE_LIST_SIZE  (MAX_MAZE_SIZE_X * MAX_MAZE_SIZE_Y)

#define TOP         0
#define RIGHT       1
#define BOTTOM      2
#define LEFT        3

#define WALL_TOP	0x8000
#define WALL_RIGHT	0x4000
#define WALL_BOTTOM	0x2000
#define WALL_LEFT	0x1000

#define DOOR_IN_TOP     0x800
#define DOOR_IN_RIGHT	0x400
#define DOOR_IN_BOTTOM	0x200
#define DOOR_IN_LEFT	0x100
#define DOOR_IN_ANY     0xF00

#define DOOR_OUT_TOP	0x80
#define DOOR_OUT_RIGHT	0x40
#define DOOR_OUT_BOTTOM	0x20
#define DOOR_OUT_LEFT	0x10

#define CHECK_TOP       0x8880
#define CHECK_RIGHT     0x4440
#define CHECK_BOTTOM    0x2220
#define CHECK_LEFT      0x1110

#define START_SQUARE	0x2
#define END_SQUARE      0x1

#define SQ_SIZE_X       10
#define SQ_SIZE_Y       10

#define NUM_RANDOM      100

#define	BORDERWIDTH     2
#define	border_x        (5)
#define	border_y        (5)
#define	MIN_W	        200
#define	MIN_H	        200

#define	DEF_W	        636
#define	DEF_H	        456

static unsigned short maze[MAX_MAZE_SIZE_X][MAX_MAZE_SIZE_Y];

static struct {
    int x;
    int y;
    int dir;
} move_list[MOVE_LIST_SIZE], save_path[MOVE_LIST_SIZE], path[MOVE_LIST_SIZE];

static int maze_size_x, maze_size_y;
static int sqnum, cur_sq_x, cur_sq_y, path_length;
static int start_x, start_y, start_dir, end_x, end_y, end_dir;

int	screen;
long	background;
int	reverse = 0;

int	width = DEF_W, height = DEF_H ;

int	x = 0, y = 0, restart = 0, stop = 1, state = 1;

int seed  = 100;

void set_maze_sizes(int w, int h);
void initialize_maze ();
void create_maze();
int choose_door();
int backup();
void draw_maze_border();
void draw_wall();
void draw_solid_square(int i, int j, int dir, int color);
void enter_square(int n);
int get_random(int x);
void clear_screen();
void paint_maze();
void solve_maze();

static CGFunctionRef myGetFunction(CGColorSpaceRef myColorspace);

void PaintMyPattern(CGContextRef context, CGRect targetRect);


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)sourceCoder
{
		if( (self = [super initWithCoder:sourceCoder] ) )
		{
			currentColor = [UIColor blueColor];
			fillColor = [UIColor greenColor];
		}
    randomMain = [NSTimer scheduledTimerWithTimeInterval:(5.0) target:self selector:@selector(paint_maze) userInfo:nil repeats:YES];

	return self;
}


- (void)drawRect:(CGRect)rect {
    
    seed = (unsigned)time ( NULL );
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    width = screenRect.size.width - 10;
    height = screenRect.size.height - 25;
    set_maze_sizes(width, height);
    
    clear_screen();
    initialize_maze();
    draw_maze_border();
    create_maze();
    solve_maze();
}

-(void) paint_maze
{
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [randomMain invalidate];
}

- (void)dealloc {
    [super dealloc];
}


int get_random(int x)
{
    seed = seed * 1103515245 + 12345;
    return (seed % ((unsigned int)RAND_MAX + 1)) % (x);
}


void set_maze_sizes(width, height)
{
    maze_size_x = width / SQ_SIZE_X;
    maze_size_y = height / SQ_SIZE_Y;
}

void clear_screen()
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGContextRef	context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, screenRect);
    CGContextStrokePath(context);
}

void initialize_maze() {         /* draw the surrounding wall and start/end squares */

    register int i, j, wall;
    
    /* initialize all squares */
    for ( i=0; i<maze_size_x; i++) {
        for ( j=0; j<maze_size_y; j++) {
            maze[i][j] = 0;
        }
    }
    
    /* top wall */
    for ( i=0; i<maze_size_x; i++ ) {
        maze[i][0] |= WALL_TOP;
    }
    
    /* right wall */
    for ( j=0; j<maze_size_y; j++ ) {
        maze[maze_size_x-1][j] |= WALL_RIGHT;
    }
    
    /* bottom wall */
    for ( i=0; i<maze_size_x; i++ ) {
        maze[i][maze_size_y-1] |= WALL_BOTTOM;
    }
    
    /* left wall */
    for ( j=0; j<maze_size_y; j++ ) {
        maze[0][j] |= WALL_LEFT;
    }
    
    /* set start square */
    wall = get_random(4);
    switch (wall) {
        case 0:
            i = get_random(maze_size_x);
            j = 0;
            break;
        case 1:
            i = maze_size_x - 1;
            j = get_random(maze_size_y);
            break;
        case 2:
            i = get_random(maze_size_x);
            j = maze_size_y - 1;
            break;
        case 3:
            i = 0;
            j = get_random(maze_size_y);
            break;
    }
    maze[i][j] |= START_SQUARE;
    maze[i][j] |= ( DOOR_IN_TOP >> wall );
    maze[i][j] &= ~( WALL_TOP >> wall );
    cur_sq_x = i;
    cur_sq_y = j;
    start_x = i;
    start_y = j;
    start_dir = wall;
    sqnum = 0;
    
    /* set end square */
    wall = (wall + 2)%4;
    switch (wall) {
        case 0:
            i = get_random(maze_size_x);
            j = 0;
            break;
        case 1:
            i = maze_size_x - 1;
            j = get_random(maze_size_y);
            break;
        case 2:
            i = get_random(maze_size_x);
            j = maze_size_y - 1;
            break;
        case 3:
            i = 0;
            j = get_random(maze_size_y);
            break;
    }
    maze[i][j] |= END_SQUARE;
    maze[i][j] |= ( DOOR_OUT_TOP >> wall );
    maze[i][j] &= ~( WALL_TOP >> wall );
    end_x = i;
    end_y = j;
    end_dir = wall;
    
}

void create_maze()             /* create a maze layout given the intiialized maze */
{
    register int i, newdoor;
    
    do {
        move_list[sqnum].x = cur_sq_x;
        move_list[sqnum].y = cur_sq_y;
        move_list[sqnum].dir = newdoor;
        while ( ( newdoor = choose_door() ) == -1 ) { /* pick a door */
            if ( backup() == -1 ) { /* no more doors ... backup */
                return; /* done ... return */
            }
        }
        
        /* mark the out door */
        maze[cur_sq_x][cur_sq_y] |= ( DOOR_OUT_TOP >> newdoor );
        
        switch (newdoor) {
            case 0: cur_sq_y--;
                break;
            case 1: cur_sq_x++;
                break;
            case 2: cur_sq_y++;
                break;
            case 3: cur_sq_x--;
                break;
        }
        sqnum++;
        
        /* mark the in door */
        maze[cur_sq_x][cur_sq_y] |= ( DOOR_IN_TOP >> ((newdoor+2)%4) );
        
        /* if end square set path length and save path */
        if ( maze[cur_sq_x][cur_sq_y] & END_SQUARE ) {
            path_length = sqnum;
            for ( i=0; i<path_length; i++) {
                save_path[i].x = move_list[i].x;
                save_path[i].y = move_list[i].y;
                save_path[i].dir = move_list[i].dir;
            }
        }
        
    } while (1);
    
}


int choose_door()                                            /* pick a new path */
{
    int candidates[3];
    register int num_candidates;
    
    num_candidates = 0;
    
topwall:
    /* top wall */
    if ( maze[cur_sq_x][cur_sq_y] & DOOR_IN_TOP )
        goto rightwall;
    if ( maze[cur_sq_x][cur_sq_y] & DOOR_OUT_TOP )
        goto rightwall;
    if ( maze[cur_sq_x][cur_sq_y] & WALL_TOP )
        goto rightwall;
    if ( maze[cur_sq_x][cur_sq_y - 1] & DOOR_IN_ANY ) {
        maze[cur_sq_x][cur_sq_y] |= WALL_TOP;
        maze[cur_sq_x][cur_sq_y - 1] |= WALL_BOTTOM;
        draw_wall(cur_sq_x, cur_sq_y, 0);
        goto rightwall;
    }
    candidates[num_candidates++] = 0;
    
rightwall:
    /* right wall */
    if ( maze[cur_sq_x][cur_sq_y] & DOOR_IN_RIGHT )
        goto bottomwall;
    if ( maze[cur_sq_x][cur_sq_y] & DOOR_OUT_RIGHT )
        goto bottomwall;
    if ( maze[cur_sq_x][cur_sq_y] & WALL_RIGHT )
        goto bottomwall;
    if ( maze[cur_sq_x + 1][cur_sq_y] & DOOR_IN_ANY ) {
        maze[cur_sq_x][cur_sq_y] |= WALL_RIGHT;
        maze[cur_sq_x + 1][cur_sq_y] |= WALL_LEFT;
        draw_wall(cur_sq_x, cur_sq_y, 1);
        goto bottomwall;
    }
    candidates[num_candidates++] = 1;
    
bottomwall:
    /* bottom wall */
    if ( maze[cur_sq_x][cur_sq_y] & DOOR_IN_BOTTOM )
        goto leftwall;
    if ( maze[cur_sq_x][cur_sq_y] & DOOR_OUT_BOTTOM )
        goto leftwall;
    if ( maze[cur_sq_x][cur_sq_y] & WALL_BOTTOM )
        goto leftwall;
    if ( maze[cur_sq_x][cur_sq_y + 1] & DOOR_IN_ANY ) {
        maze[cur_sq_x][cur_sq_y] |= WALL_BOTTOM;
        maze[cur_sq_x][cur_sq_y + 1] |= WALL_TOP;
        draw_wall(cur_sq_x, cur_sq_y, 2);
        goto leftwall;
    }
    candidates[num_candidates++] = 2;
    
leftwall:
    /* left wall */
    if ( maze[cur_sq_x][cur_sq_y] & DOOR_IN_LEFT )
        goto donewall;
    if ( maze[cur_sq_x][cur_sq_y] & DOOR_OUT_LEFT )
        goto donewall;
    if ( maze[cur_sq_x][cur_sq_y] & WALL_LEFT )
        goto donewall;
    if ( maze[cur_sq_x - 1][cur_sq_y] & DOOR_IN_ANY ) {
        maze[cur_sq_x][cur_sq_y] |= WALL_LEFT;
        maze[cur_sq_x - 1][cur_sq_y] |= WALL_RIGHT;
        draw_wall(cur_sq_x, cur_sq_y, 3);
        goto donewall;
    }
    candidates[num_candidates++] = 3;
    
donewall:
    if (num_candidates == 0)
        return ( -1 );
    if (num_candidates == 1)
        return ( candidates[0] );
    return ( candidates[ get_random(num_candidates) ] );
    
}


int backup()                                                  /* back up a move */
{
    sqnum--;
    cur_sq_x = move_list[sqnum].x;
    cur_sq_y = move_list[sqnum].y;
    return ( sqnum );
}


void draw_maze_border()                                  /* draw the maze outline */
{
    register int i, j;
    
    CGContextRef	context = UIGraphicsGetCurrentContext();
	
	CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
   
    for ( i=0; i<maze_size_x; i++) {
        if ( maze[i][0] & WALL_TOP ) {
            CGContextMoveToPoint(context,
                      border_x + SQ_SIZE_X * i,
                                 border_y);
            CGContextAddLineToPoint(context,
                     border_x + SQ_SIZE_X * (i+1),
                      border_y);
            CGContextStrokePath(context);
        }
        if ((maze[i][maze_size_y - 1] & WALL_BOTTOM)) {
            CGContextMoveToPoint(context,
                      border_x + SQ_SIZE_X * i,
                                 border_y + SQ_SIZE_Y * (maze_size_y));
            CGContextAddLineToPoint(context,
                      border_x + SQ_SIZE_X * (i+1),
                      border_y + SQ_SIZE_Y * (maze_size_y));
            CGContextStrokePath(context);
        }
    }
    for ( j=0; j<maze_size_y; j++) {
        if ( maze[maze_size_x - 1][j] & WALL_RIGHT ) {
            CGContextMoveToPoint(context,
                      border_x + SQ_SIZE_X * maze_size_x,
                                 border_y + SQ_SIZE_Y * j);
            CGContextAddLineToPoint(context,
                      border_x + SQ_SIZE_X * maze_size_x,
                      border_y + SQ_SIZE_Y * (j+1));
            CGContextStrokePath(context);
        }
        if ( maze[0][j] & WALL_LEFT ) {
            CGContextMoveToPoint(context,
                      border_x,
                      border_y + SQ_SIZE_Y * j);
            CGContextAddLineToPoint(context,
                      border_x,
                      border_y + SQ_SIZE_Y * (j+1));
            CGContextStrokePath(context);
        }
    }
     
    draw_solid_square( start_x, start_y, start_dir, 1);
    draw_solid_square( end_x, end_y, end_dir,1);
}


void draw_wall(i, j, dir)                                   /* draw a single wall */
int i, j, dir;
{
    CGContextRef	context = UIGraphicsGetCurrentContext();
	
	CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
    
    switch (dir) {
        case 0:
            CGContextMoveToPoint(context,
                      border_x + SQ_SIZE_X * i,
                      border_y + SQ_SIZE_Y * j);
            CGContextAddLineToPoint(context,
                      border_x + SQ_SIZE_X * (i+1),
                      border_y + SQ_SIZE_Y * j);
            break;
        case 1:
            CGContextMoveToPoint(context,
                      border_x + SQ_SIZE_X * (i+1),
                                 border_y + SQ_SIZE_Y * j);
            CGContextAddLineToPoint(context,
                      border_x + SQ_SIZE_X * (i+1),
                      border_y + SQ_SIZE_Y * (j+1));
            break;
        case 2:
            CGContextMoveToPoint(context,
                      border_x + SQ_SIZE_X * i,
                                 border_y + SQ_SIZE_Y * (j+1));
             CGContextAddLineToPoint(context,
                      border_x + SQ_SIZE_X * (i+1),
                      border_y + SQ_SIZE_Y * (j+1));
            break;
        case 3:
            CGContextMoveToPoint(context,
                      border_x + SQ_SIZE_X * i,
                                 border_y + SQ_SIZE_Y * j);
            CGContextAddLineToPoint(context,
                      border_x + SQ_SIZE_X * i,
                      border_y + SQ_SIZE_Y * (j+1));
            break;
    }
    
        CGContextStrokePath(context);
}


void draw_solid_square(i, j, dir, color)          /* draw a solid square in a square */
register int i, j, dir, color;

{
    CGContextRef	context = UIGraphicsGetCurrentContext();
	
    if (color==1) {
        CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    }
    else {
        CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
    }
    

    switch (dir) {
        case 0: CGContextFillRect(context, CGRectMake(
                               border_x + 3 + SQ_SIZE_X * i,
                               border_y - 3 + SQ_SIZE_Y * j,
                               SQ_SIZE_X - 6, SQ_SIZE_Y));
            break;
        case 1: CGContextFillRect(context, CGRectMake(
                               border_x + 3 + SQ_SIZE_X * i,
                               border_y + 3 + SQ_SIZE_Y * j,
                               SQ_SIZE_X, SQ_SIZE_Y - 6));
            break;
        case 2: CGContextFillRect(context, CGRectMake(
                               border_x + 3 + SQ_SIZE_X * i,
                               border_y + 3 + SQ_SIZE_Y * j,
                               SQ_SIZE_X - 6, SQ_SIZE_Y));
            break;
        case 3: CGContextFillRect(context, CGRectMake(
                               border_x - 3 + SQ_SIZE_X * i,
                               border_y + 3 + SQ_SIZE_Y * j,
                               SQ_SIZE_X, SQ_SIZE_Y - 6));
            break;
    }

    CGContextStrokePath(context);

}

void solve_maze()                             /* solve it with graphical feedback */
{
    int i;
    
    
    /* plug up the surrounding wall */
    maze[start_x][start_y] |= (WALL_TOP >> start_dir);
    maze[end_x][end_y] |= (WALL_TOP >> end_dir);
    
    /* initialize search path */
    i = 0;
    path[i].x = end_x;
    path[i].y = end_y;
    path[i].dir = -1;
    
    /* do it */
    while (1) {
        if ( ++path[i].dir >= 4 ) {
//            draw_solid_square( (int)(path[i].x), (int)(path[i].y),(int)(path[i].dir),0);
            i--;
            draw_solid_square( (int)(path[i].x), (int)(path[i].y),(int)(path[i].dir),0);
        }
        else if ( ! (maze[path[i].x][path[i].y] & 
                     (WALL_TOP >> path[i].dir))  && 
                 ( (i == 0) || ( (path[i].dir != 
                                  (int)(path[i-1].dir+2)%4) ) ) ) {
            enter_square(i);
            i++;
            if ( maze[path[i].x][path[i].y] & START_SQUARE ) {
                return;
            }
        } 
    }
} 


void enter_square(n)                            /* move into a neighboring square */
int n;
{
    draw_solid_square( (int)path[n].x, (int)path[n].y, (int)path[n].dir,1);
    
    path[n+1].dir = -1;
    switch (path[n].dir) {
        case 0: path[n+1].x = path[n].x;
            path[n+1].y = path[n].y - 1;
            break;
        case 1: path[n+1].x = path[n].x + 1;
            path[n+1].y = path[n].y;
            break;
        case 2: path[n+1].x = path[n].x;
            path[n+1].y = path[n].y + 1;
            break;
        case 3: path[n+1].x = path[n].x - 1;
            path[n+1].y = path[n].y;
            break;
    }
}


@end
