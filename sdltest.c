#include <SDL/SDL.h>

//http://lazyfoo.net/SDL_tutorials/lesson01/index2.php
//
int main(int argc, char* argv[]) {
	SDL_Surface* hello = NULL;
	SDL_Surface* screen = NULL;

	SDL_Init(SDL_INIT_EVERYTHING);

	screen = SDL_SetVideoMode(640, 480, 32, SDL_SWSURFACE);

	hello = SDL_LoadBMP("test.bmp");

	SDL_BlitSurface(hello, NULL, screen, NULL);
	SDL_Flip(screen);
	SDL_Delay(1000);
	SDL_FreeSurface(hello);
	SDL_Quit();
	return 0;
}
