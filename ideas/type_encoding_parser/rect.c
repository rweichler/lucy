
typedef struct point {
    float x;
    float y;
} point;

typedef struct size {
    float w;
    float h;
} size;

typedef struct rect {
    point origin;
    size size;
} rect;

rect make_rect(float x, float y, float w, float h)
{
    rect r;
    r.origin.x = x;
    r.origin.y = y;
    r.size.w = w;
    r.size.h = h;
    return r;
}

float get_width(rect r)
{
    return r.size.w;
}

float (*lol)(struct {
                struct {
                    float x;
                    float y;
                } origin; 
                struct {
                    float w;
                    float h;
                } size;
            } a);
