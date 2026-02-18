void kmain()
{
    volatile char* video = (volatile char*)0xb8000;

    char* text = "ColrsOS Kernel Started!";

    while(*text)
    {
        *video = *text;
        video++;
        *video = 0x04;
        video++;
        text++;
    }

    while(1){}
}
