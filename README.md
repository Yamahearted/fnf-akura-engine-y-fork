![Header](https://cdn.discordapp.com/attachments/862777578325671986/995774580562067538/akuraenginebanner-2.png)

A recreation of the newest popular rhythm game, [Friday Night Funkin'](https://ninja-muffin24.itch.io/funkin) made in [Godot-engine](https://godotengine.org).

( with a ton of performance improvements to run on lowendpcs, and 10x faster to compile and export a build/mod )


## How to make a mod ( non executable way )
The way it works, it's a little different, if you're curious how godot handles it, [check this documentation(https://docs.godotengine.org/en/stable/tutorials/export/exporting_pcks.html)
Clone the source, edit it as much as you want on godot, make sure to download the export features, and export the game as .pck

Make a folder in your desktop (whatever), like "mod"
and you're going to need some crucials files to make it work

![image](https://user-images.githubusercontent.com/89349204/178160168-f8ec44c0-fc7a-4583-883b-15eb4a6ac32e.png)

icon.png will be your mod icon (duh)
package.json is the data like, name, description.
screenshorts/ is a folder to place images of your mod, so it can be shown at the mods menu.
mod.pck is the file you just exported from godot.

now, to play it, you'll need a builded version of the game, that you can find here on the releases.
open the game once, so the /appdata folders can be created.

put the mod folder you created inside of /appdata/roaming/akura-engine/mods
now open your game, go to mods, and you'll probably see something like this.

# Final result in-game
![image](https://user-images.githubusercontent.com/89349204/178160231-b3b57bb5-7401-452d-8904-4b0443944a8a.png)



## Credits
Friday Night Funkin' - ninja_muffin99, PhantomArcade3k evilsk8r, kawaisprite

Recreation/Engine - Aküra
