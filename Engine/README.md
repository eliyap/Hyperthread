#  Hyperthread Engine
These files represent the core of the application.
Our primary goal is to take incoming tweets, and weave them into coherent "Discussions".
- coherent: this means every tweet must be attached to its associated "context"
- "context: the tweet a tweet was replying to, quoting (or both), the tweets _that_ was replying to, etc.

Secondarily, we also aim to "maintain" discussions, 
- e.g. by pruning tweets from people the user no longer follows. 
