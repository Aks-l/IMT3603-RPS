# Game Programming Submission

## Group Component

### Team Members (Legal Name - NTNU handle - Discord handle - GitHub handle)
- Katharina Kivle - katharki - @klaoj - @katharki
- Nikolai Olav Stubø - nikolos - @daniel_dogg - @HexactlyA
- Aksel Holmstrøm Wiersdalen - akselhw - @masterjeb - @aks-l

### Gameplay Video
[Link to gameplay video](https://youtu.be/4VFcysTtJPU)

### Development Process Discussion

We chose to use **Godot 4.4** as our game engine due to its user-friendly interface and robust features for 2D game development and that it came recommended smaller sized teams and projects. The engine's built-in tools for animation, physics, and scripting with GDScript allowed us to rapidly prototype and iterate on our game mechanics.


**Strengths:**

During development, we identified several strengths in using Godot as our game engine.

The main advantage of Godot for our project was its relatively gentle learning curve compared to engines such as Unity or Unreal Engine. Since none of the team members had prior experience with game development or game engines, this made it possible for everyone to quickly become familiar with both GDScript and Godot’s scene system.

Because of this ease of use, we were able to prototype and iterate on game mechanics fairly quickly once we had a basic understanding of the engine. This was especially useful during the early stages of development, where experimenting with ideas and making frequent changes was important.

For our specific project, we were able to take advantage of Godot’s strengths in 2D game development. Its node-based architecture and built-in support for managing scenes and game states worked well for our design, for example when instantiating battle scenes, shops, and events from the main map scene.

We also found GDScript to be a simple and effective scripting language that allowed us to implement game logic without the overhead of more complex languages such as C# or C++. This was particularly helpful for a small team, as it allowed us to focus more on gameplay and design rather than dealing with language complexity.

Another benefit of Godot is that it is lightweight and open source. This made it easy for all team members to install and use, without concerns about licensing or high system requirements. The engine also ran smoothly on everyone’s machines, helping to avoid technical issues. Additionally, the use of packed scenes and instancing supported a modular workflow, allowing us to reuse UI elements, enemies, and events across different parts of the game.

Overall, Godot provided a solid foundation for our development process and enabled us to deliver a functional and engaging game within the limits of our project timeline and the team’s experience level.

**Weaknesses:**

We encountered several challenges while using Godot for this project.

Because our game was a deck-building roguelike rather than a more common genre such as a 2D platformer, we found that Godot offered fewer pre-built nodes and ready-made solutions relevant to our needs. As a result, many core systems had to be implemented from scratch, which increased development time.

We also experienced difficulties when working in a shared repository. Godot’s tendency to generate new UIDs for nodes across different machines often caused merge conflicts when multiple team members worked on the same scene files. This meant we had to be more cautious with scene editing and communicate clearly about who was responsible for which parts of the project.

Another issue arose from documentation and online resources. A large portion of available tutorials and examples are written for Godot 3.x without clearly indicating this. Since our project used a newer version of Godot, differences in the signaling system, APIs, and general workflows sometimes led to confusion and implementation errors. Additional time was often needed to identify these version differences and adapt solutions accordingly.

While Godot’s signaling system is powerful, it also introduced its own challenges. Signals can easily create dependencies that are difficult to track and debug, particularly for developers new to the engine. The mix of signals connected through the editor and those connected in code further complicated tracing where signals originated and how they were used.

Finally, all team members were new to Godot, so getting used to the IDE and overall workflow took time. This initial learning curve slowed development during the early stages of the project.


**How process and communication were controlled**

Discord has been used as the main communications channel during development. In addition to the main discord channel used by the course, we used an internal channel to keep each other updated on which features each group member was working on, as well as what our next priorities would be.

GitHub was used as out version control system, and whenever a new pull request was created, the member who created it would tell the other members in the designated Discord channel in addition to requesting a review on GitHub. From there on, conversation regarding the merge would take place in the merge request itself.

Our group consists of students who are regularly attending classes and generally working on assignments on campus. This caused us to discuss the project regularly, making us feel like regular meetings were not necessary. Instead, we would discuss our progress and next steps in the Discord channel or in person as needed.


**Use of version control systems, ticket tracking, branching, etc.**

As we used GitHub for version control, we strived to create one branch per feature, to ensure mangable merge requests that don't grow out of hand. A feature of GitHub that GitLab lacks is the ability to ask CoPilot for a review in a pull request. We used this frequently to get an initial review of code before asking another human to review.

We have not used GitHub's issue tracker, but rather kept track of tasks in the Discord channel. This was beneficial, as we had little prior knowledge of Godot, and despite having an idea of the end result, we did not have many concrete tasks to start with. Discord worked well as an alternative, since it acts as an easy form of discussing potential new features and ideas.

In lieu of issue tracking, we have made sure to keep all team members in the loop regarding what other members are working on. This has been done mostly through daily in-person and online communication.

In all this has worked well for our team, as we have been able to avoid major merge conflicts and keep each other updated on progress without spending too much time on project management.

**Work separation**

| Feature           | Katharina | Nikolai | Aksel   | 
|---------          |-----------|---------|---------|
| Main menu         |           | Touched | Most    | 
| Map               |           | All     |         | 
| Battle Scene      | Some      |         | Most    |
| Battle Logic      | Most      | Some    |         |
| Shop              |           |         | All     |
| Events            |           | All     |         |
| Enemies           | All       | Touched | Touched |
| UI                | Some      | Half    | Some    |
| Save System       |           |         | All     |
| Biome Database    |           |         | All     |
| Enemy Database    | All       |         |         |
| Event Database    |           | All     |         |
| Item Database     |           |         | All     |
| Hand Database     | Touched   | Touched | All     |
| Encounter Handler | Touched   | Most    | Some    |
| Deck Creator      | Most      |         | Some    |
| Inventory         | Touched   | Some    |         |
| Almanac           |           |         | All     |
| Victory Scene     |           | Some    | Most    |
| Globals           | Some      | Some    | Some    |
| Audio Player      |           |         | All     |
| HandGraph         |           | All     |         |

