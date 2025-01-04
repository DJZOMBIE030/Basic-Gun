Hello there, Aplication Reader! (Hi again to Scriptone if you're reading mine again.)

In this repository, you'll find two scripts. They're both the same. Just one has an essay worth of comments explaining the code and the other one doesn't so you can actually read it lol.
I also don't know HOW detailed you guys want the explaination, so I kind of went all out (might be an understatement... or an overstatement).
So, if you want, just read through the code in the one without comments, and if you want my explaination for a part of the code, look at the one with the comments.
Also, I have made the game open to edit. So, if you want, you can edit the game and look at the scripts in there (both commented and uncommented are there). The scripts are in StarterCharacterScripts.

Game: https://www.roblox.com/games/124061680189008/Basic-Gun

Sometimes when I'm looking at other people's code, I see them use "task.wait()" instead of "wait()" and I always wondered "Why? What's the difference?"
Whelp... I found out what I was using that was deprecated: wait().
That was a complete surprise to me. I found this out around an hour and a half ago. I had no clue Roblox changed that (even though they did it almost(?) 3 years ago).
So, after some reading, I finally have my answer to those questions. In short, task.wait() is better (faster) and more reliable (it also doesn't have a minimum of 29ms).
