# ToDo 
## High Priority:
- [x] rewrite as class
- [x] test all goals
- [x] implement a goal only requiring to collect the required location count
  - [x] test
- [x] fix restock override
  - [x] breaks with binge eater.....
    - [x] steam sale doesn't work now prolly.......
      - [x] test multiple steam sales
- [x] look into RNG, we seem to get the same cards/pill when we spawn stuff quickly
- [x] prevent spawning items on top of ... (esp. when run start with many items)
  - [x] other items
  - [ ] player `-> seems to not work as the player is moving during start (from center pos to actual start pos). will probably not fix`
- [x] fix collect behavoir
  - [x] collect seems to crash sometimes? maybe forfeit too? `fixed... I think?`
- [x] implement all collectables for start inv
- [x] boss rewards
  - [x] crashes on beast
  - [x] fix most boss shouldnt give reward on delirum stage
- [x] go thru the discord thread for potential other options/functions
- [x] traps
  - [ ] more traps!
- [x] death link
- [x] datapackage version caching
  - [x] needs RoomInfo fix
    - [x] better caching ~~with seperate files~~
- [x] use RNG class from TBoI for hopefully better RNG
- [x] fix bug were we increase item step but not collect item!
- [ ] wighting / balancing
- [ ] test with all chars (esp. Tainted Chars)

## Maybe Later:
- [ ] figure out a better way to input AP host/port/slot name/password
- [ ] look into non blocking with socket.select
- [ ] whatever other great options AP has I don't know about