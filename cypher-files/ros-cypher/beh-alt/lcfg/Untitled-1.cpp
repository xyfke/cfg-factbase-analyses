int foo(int x) {        // foo():CFG:ENTRY
    if (x  > 5) {       // foo():CFG:3
        return x * 2;   // foo():CFG:2
    } else {
        return x * 3;   // foo():CFG:1
    }
}                       // foo():CFG:0 (EXIT)

int goo(int z) {    
    int y = foo(z);     // goo():CFG:1
}