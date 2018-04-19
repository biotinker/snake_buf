# snake_buf
A version of the classic Snake game that writes directly to the framebuffer

One dependency: the perl Term::ReadKey package.

Also, your user must be a member of the "video" group. You will probably need to add yourself.

Just run in a tty with:
`perl snake_buf.pl <MONITOR_WIDTH> <MONITOR_HEIGHT>`
So for example
`perl snake_buf.pl 1920 1080`
