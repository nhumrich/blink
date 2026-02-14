#include "runtime.h"

static pact_ctx __pact_ctx;

typedef struct {
    int tag;
    union {
        struct {
            double radius;
        } Circle;
        struct {
            double width;
            double height;
        } Rectangle;
    } data;
} pact_Shape;

#define pact_Shape_Circle_TAG 0
#define pact_Shape_Rectangle_TAG 1
#define pact_Shape_Point_TAG 2


double pact_area(pact_Shape s);
const char* pact_describe(pact_Shape s);
void pact_main(void);

double pact_area(pact_Shape s) {
    pact_Shape _scrut_0 = s;
    double _match_1;
    if ((_scrut_0.tag == 0)) {
        double r = _scrut_0.data.Circle.radius;
        _match_1 = ((3.14159 * r) * r);
    } else if ((_scrut_0.tag == 1)) {
        double w = _scrut_0.data.Rectangle.width;
        double h = _scrut_0.data.Rectangle.height;
        _match_1 = (w * h);
    } else if ((_scrut_0.tag == 2)) {
        _match_1 = 0.0;
    }
    return _match_1;
}

const char* pact_describe(pact_Shape s) {
    pact_Shape _scrut_0 = s;
    const char* _match_1;
    if ((_scrut_0.tag == 0)) {
        _match_1 = "circle";
    } else if ((_scrut_0.tag == 1)) {
        _match_1 = "rectangle";
    } else if ((_scrut_0.tag == 2)) {
        _match_1 = "point";
    }
    return _match_1;
}

void pact_main(void) {
    const pact_Shape c = (pact_Shape){.tag = 0, .data.Circle = {.radius = 5.0}};
    const pact_Shape r = (pact_Shape){.tag = 1, .data.Rectangle = {.width = 3.0, .height = 4.0}};
    const pact_Shape p = (pact_Shape){.tag = 2};
    printf("%s\n", "Circle area:");
    printf("%g\n", pact_area(c));
    printf("%s\n", "Rectangle area:");
    printf("%g\n", pact_area(r));
    printf("%s\n", "Point area:");
    printf("%g\n", pact_area(p));
    printf("%s\n", pact_describe(c));
    printf("%s\n", pact_describe(r));
    printf("%s\n", pact_describe(p));
}

int main(int argc, char** argv) {
    pact_g_argc = argc;
    pact_g_argv = (const char**)argv;
    __pact_ctx = pact_ctx_default();
    pact_main();
    return 0;
}