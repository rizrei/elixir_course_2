# PlanningPoker

A simple TCP application for planning tasks in rooms using voting. It listens for incoming connections on the default port `4040`, accepts text commands, and returns responses as a single text message.

## Running

1. Install dependencies:

```bash
mix deps.get
```

2. Run the application:

```bash
mix run --no-halt
```

By default, the application listens on port `4040`.

## Connecting via telnet

Open a new terminal window and connect to the service:

```bash
telnet localhost 4040
```

Once connected, you can send commands as strings terminated by a newline (`Enter`).

## Available commands

### User commands

- `login <username>` — log in with a username.
- `logout` — end the current user's session.

### Room listing commands

- `list` — show the list of all rooms.
- `show <room_name>` — show the state of a room.

### Room management commands

- `create <room_name>` — создать комнату.
- `delete <room_name>` — удалить комнату.

### Room participation commands

- `join <room_name>` — create a room.
- `leave <room_name>` — delete a room.

### Voting and topic

- `topic <room_name>:<topic>` — set a topic for the room.
- `vote <room_name>:<vote>` — vote on a task in the room.

## Usage examples

```bash
telnet localhost 4040

login Alice
create backend
join backend
topic backend:new_topic
vote backend:5
show backend
logout
```
