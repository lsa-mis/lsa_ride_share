# On Documentation
[Home](./README.md) / [Development](development/README.md)

___

Here are some thoughts on documentation, where I believe it should live, and why. 

> **TL%DR** 
> Documentation should live as close to the product that it is documenting. In practice, this means that it is maintained withing the product itself. Centralized knowledgebase(s) etc should point to the documentation within the product. Following consistent patterns for where we put documentation will make finding contectually approriate information easily.

#### Definitions:
  ***product*** I will be using the term ***product*** to be defined as a cohesive chunk of functionality. A ***product*** can have multiple other products that it is dependent upon. An imperfect, but fairly good analogy would be a git repository. I useful heuristic is; "If it is cohesive enough to merit a repository, it is probably a 'product'." 

> I think about code in terms of products even when it pertains to modules or shared libraries that aren't readily visible to our end users, but nonetheless, are products that our developers use to build the products that end users interact with. In some cases, the module might only be used by one developer, in one context. It is this a product that that developer built and uses. ***Developers are ALWAYS customers!!!*** 

  ***user*** Anyone who interacts with the product in any way. This can include:
    - **end-user:** interact with the developed user interface for a product.
    - **developer:** anyone who touches the code
    - **designer:** provides input into the design and/or creates media 
    - **tester:** q/a etc...
    - **support:** help desk, triage routing.


## What format/language(s) for documentation in?

Given the nature of our work developing for the internet, we want our documentation to be accessible in that medium. So, documentation needs to be delivered in html. This can be accomplished by either writing it directly in html, integrating it into the application (that generates and presents the information as html), or using a language like Markdown that gets parsed to html. 

Using html as the basis gives us the most flexibility. We can re-use it in different avenues (if needed), generate pdfs, etc...

### Markdown

**I had ChatCPT Help me with this part:**
>>> Markdown is a lightweight and simple markup language used for formatting text documents. It uses a plain-text format that is easy to read and write, making it a popular choice for documentation among developers.
>>>
>>> One of the key benefits of using Markdown for documentation is its flexibility. It can be used to format text in a variety of ways, including headings, lists, links, and images, while keeping the formatting simple and straightforward. This makes it a great choice for teams that need to collaborate on documentation, as it is easy for both technical and non-technical collaborators to read and contribute to the content.
>>>
>>> Another benefit of Markdown is its accessibility. Because it uses plain text, it is easily accessible to people with disabilities and can be processed by screen readers and other assistive technologies. This helps ensure that the documentation is usable by a wide range of people, making it a more inclusive choice.
>>>
>>> Finally, Markdown's simplicity makes it an ideal choice for documentation because it allows developers to focus on the content rather than the formatting. This can lead to faster and more efficient documentation creation, as well as easier maintenance and updates.

Markdown also encourages us to focus on writing clear documentation using prose (as opposed to images etc...). While other rich media can be included, the medium focusses on plain text.

Oh, AND Markdown documents can be edited directly on GitHub.


## Where should it live?
As I've shared before, I believe documentation should live with the product. The benefits, to my mind, are manifold.

- Documentation is a ***core*** part of each product we produce.
  - We don't consider a product complete unless it has up-to-date documentation.
  - Keeping documentation within the product reinforces this.
- Consistent place to direct users.


## What about TDX?

In scenarios where we have a centralized 'knowledge base' system we are encouraged to user, the entries in the knowledge base should direct users to the product's documentation page or url. 

> For example: An entry in the TDX knowledge base for the MClassrooms project would be  something like: 
> 
> MClassrooms provides information about classrooms in the academic units at the University of Michigan.
>  For detailed information about the MClassrooms project visit:
  >- [About MClassrooms](https://mclassrooms.umich.edu/about) 
  >- [How to use MClassrooms](https://mclassrooms.umich.edu/docs)
  >- [Developer Documentation](https://github.com/lsa-mis/mi_classrooms)
  >- [Requesting support for MClassrooms](https://mclassrooms.umich.edu/support)

Which links are included in the knowledge base will depend on the nature of the product. If the product is a module that is used by developers in another product for example, there would be one url pointing to the README file in the git repository. 

## README!!!!s

Every product's codebase needs, at a minimum, an up to date README file that documents how to get started working with that product. It defines the required dependencies, setup steps etc...

The readme is ***NOT*** intended to be documentation for end-users. It is primarily focussed on developers and, possibly, people providing technical support. 

The codebase README.md need the following:

- [ ] A description of the product
- [ ] Instructions for how a developer or support person can set up their environment to allow them to run it in their development environment. 
  - [ ] Dependencies 
  - [ ] Database setup/seed data
  - [ ] Environment variables / configuration(s) for external APIs etc...
- [ ] Instructions for running tests / verifying that the product is working as expected.


## What about Google Docs and being about to collaborate with non-developers on documentation?

Collaborating on writing documentation utilizing tools like Google Docs is a great way to compose the documentation. The end product however, needs to be incorporated into the product itself. 


