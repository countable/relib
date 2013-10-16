This codebase is currently exploratory and very likely to change. This repository is mostly a list of complaints I have about the state of web app development tooling, and some experiments in addressing these.

# ReLib
I want to have my cake and eat it too when I'm programming. I love this expression. To "have my cake" is utterly pointless if I can't eat it. And, I can't "eat it" unless I "have my cake" first. So this applies to situations where a requisite step is applies before one can achieve a desired result. In client side MVC, the analogy is wanting to have cool tools and actually use them to produce great software. I've used a great variety of web application development tools on the client, and while they implement some really cool ideas, I want to be free from the constraints imposed by many of these ideas (some of which stem from the history of MVC), while still having the benefits of loose architectural conventions and ability to automate the grunt work of writing a client side app. I don't want to think about the order my application components load. I just want to declare the behaviour of my application using an efficient syntax. The further any abstractions take me from this task, the lower my happiness becomes, and the more I lose faith in the tools and practices of the web developer community. I have the sinking feeling that we have become obsessed with building tools at the expense of using tools.

# ReModel
Thesis: Traditional MVC models are too heavy and prescriptive. They block the power of lower abstractions under the guise of "protecting" "userland" "developers". This attitude hails from the days of Java and is outmoded now.
- Having a model should never be less convenient than storing object literals in an array.
- Models should be implemented on a convenience basis, as shallow wrappers around simple object lists. "Hydration" is a good concept used by Mongoose, a MongoDB ORM, because it implies a duality between structured and unstructured data.
- Easy to manipulate in arbitrary ways. ie) Trivial to inject pre-loaded data. It's been said that a combination of client and server-side rendering is necessary for top performing web apps. This isn't (as) true if we pre-load data on the client because it can render there instantly, and then we only need a single render pipeline. The performance benefits here are introduced by eliminating latencies from chained dependency loading, not the actual rendering routines happening on the server, although you could do that with shared logic too.

# ReView (views and controllers)
Note: Frameworks differ on the definitions of view and controllers. In this case, views are what the user sees on the screen, and controllers refer to part of the application that provides the interface between the UI (view) and any saved data (model).

# views
There are complaints that the DOM and HTML are deficient for writing views so we need to "augment" them (AngularJS) or generate them using a domain specific language (template language). I'd argue that HTML is just fine for layouts. All the extensions mentioned are concerend with binding data to the dom, or implementing behaviour. But the view isn't meant for behaviour! There are arguments out there that HTML was designed for rendering documents, not applications. Several ther UI frameworks designed for (yes) writing applications explicitly chose to use XML for views. My hunch is we are secretly craving to do things the "PHP way" when our minds deviate to something that violates a basic idea of MVC (separation of concerns) so blatantly as templates. I realize I'm championing seemingly arbitrary ideas of MVC and eschewing others. In fact, my goal is to carefully consider which of these ideas offer value in terms of making it easier to write software.
- Views should only define layout, and should NOT define behaviour.
- Views should be pure HTML.

# controllers
Writing web apps is often an exercise in implementing CRUD (create, read, update, delete) repeatedly. The coding is so repetitive at times as to make me lose focus and start writing buggy code. Am I not a programmer, and isn't the purpose of being one to automated repetition in cases where there are obvious patterns? CRUD should require almost zero code. If I have some data, I should just need to specify whether I want CRUD or not, and how the UI looks. Nothing I've seen is anywhere close to this.

Now, let me count the days I've spent structing class based view code to manage instances of sub-views. Let's expand on the prior stated definition of controller. Since the controller interfaces the user and model, it doesn't actually initiate any behaviour on its own. Anything it does can be described as responding to some kind of event. So a controller is a set of event handlers. It responds to events initiated by the user, and updates the model and view accordingly. Sometimes, the updates to the model may also imply further changes to the view. So the controller is just a list of event handlers. Client side implementations require managing instances of controllers that directly map to the currently visible or available UI. I've yet to see the benefit of doing this, only the agony of instantiating, managing, garbage collecting, debugging an heirarchy of object instances with dependencies that require loading in specfic orders. Maybe I'm "doing it wrong", but I'll just declare what parts of my UI do what in a simple list. Any persistent data that's needed for the UI doesn't need to go in the controller anyway. It can live in the model or the dom (view). To recap, controllers should give us:
- Fully automated CRUD.
- Tools to partly if not fully automate DOM updates (Meteor and AngularJS have done a good job already here.)
- Reduce controllers to an unstructured list of event handlers.

# ReForm
Forms are a special type of view and controller we should make special note of, because they comprise a very large part of the "meat" of apps, and have complex but predictable behaviour. Forms require rendering a list of inputs or widgets, and are used to enter data, validate it, display and handle validation errors, save data to a model, and display it again. Django has a beautiful Form abstraction that seemlessly handles all these actions in a mostly declarative way.
- Define forms in JSON, with optional layout specifiers elsewhere
- Automate the rendering, validation, submission and retrieval of form data.

# ReRoute?
Thesis: Routes don't actually make a lot of sense. URLs never evolved to be part of desktop applications, because they're rarely a helpful paradigm for apps. They're only part of web apps becuase of their "web" heritage but that doesn't validate their existence on its own. On the rare occasion that I want a unique string to capture and share my application state, it's an extremely simple problem to solve by hand without routes. For certain specific applications they may find utility but I'd hesitate to include them in a general web application framework for risk of promoting their use when unneeded.
- ReRoute does not exist. If you must use routes, use Page.js, it's the best of all the popular client routers. (I've tried quite a few of these)

# Demos
Coming soon... I've used the included components in production applications but don't have any active demos yet.
