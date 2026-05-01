Subject: request for review: Debian packaging docs for coding agents

Hi,

I wanted to share an agent skill I'm using to build Debian packages:

https://github.com/cosgroveb/debian-packaging-agent-skill

This is for internal packages at work. In the past we've used fpm, alien, etc. Sometimes I just pray packages from testing will install on oldstable, etc.

Once in a great while, I'll upstream a patch:

https://www.postgresql.org/message-id/CAOMoQbRuzPRmYm7MpQ2PcAvbCPTb8i0BT54AF70_wuC6%3DMJw4g%40mail.gmail.com

People shouldn't inflict slop package source on maintainers. This can save time, though. With something like it a thoughtful dev's patch can start closer to what maintainers expect. 

Please check for:

- advice that is wrong
- advice that would produce broken packages
- anything that should be required before asking a human to review output
- language-specific traps, especially Rust/debcargo and Go

Not asking anyone to endorse this or lower review standards. Just trying to keep thoughtful and intentional use of GenAI assistance from wasting anyone's time.

Brian Cosgrove
