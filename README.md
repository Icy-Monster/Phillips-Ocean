# Summary
This is an implementation of an Ocean-Spectra, the Philips spectrum, to be exact. It uses Fast Fourier transforms (FFT) to efficiently and quickly generate waves. It uses the [EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh) instance to its fullest, vertex’s positions and even normals are changed each frame! The project offers wide customizations to artists, to get any type of sea environment that one may need— and it’s even fully open sourced, so anyone can take a look inside and see how it is made. And to top it all of it also includes water caustics using an [EditableImage](https://create.roblox.com/docs/reference/engine/classes/EditableImage) by using Snell's law in reverse to create almost physically accurate but still fast caustics. 

This project took quite a long time to create and finish, starting all the way in September 2023 and ending in April 2024, but do be aware that there were long breaks in between. There is also a good chance that I continue development on this to implement features such as foam (this has been added!), I've already looked around and encountered 2 ways of implementing it: using a Jacobian Matrix, which is what is being used in Sea of Thieves (which was a big inspiration for this project), or the naive method that was used by NVIDIA in GPU Gems 2: Chapter 18 where they simply looked at the height of the water to determine the choppiness. Both implementations have their pros and cons but that will ultimately come down to the one that fits this project best.

And lastly I wanted to mention 2 things:
1. A big thank you to the Roblox Staff that chose my project to be showcased in the [2023 Year in Review](https://devforum.roblox.com/t/2023-year-in-review-extreme-wall-running-rhythmic-ocean-waves-demonic-heads-and-more/2748060), sadly the showcase that I displayed there was an older version, that was lacking quite a lot.
2. The default settings of this project are meant to stress test it, so I greatly recommend you change the Fourier size to 64.

# Showcase
![](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/5X/2/2/8/6/228640c16cdf4eca6bd2caa52f49911028166d98.png)

You can see both the caustics and water here, caustics are almost physically accurate, so they are dependant on the water..

![](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/5X/a/d/b/f/adbf084825349b716a7173d203de48288d53d0f7.mp4)

Here's a newer version that includes texture blending
****
![](https://github.com/user-attachments/assets/feaa12be-1290-4a3a-ad82-0a25f33e87a9)

The caustics are fully linked to the sun, so if the sun is down there will be less light to bounce through the water.
****
![](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/optimized/5X/2/6/a/f/26afd0cfdb924924a80057179a74bfe07a1ae169_2_690x339.png)

You can fully see the caustics here, which are all derived from the sun and normal of the water. Specifically they use Snell's law in reverse, so they are very close to being physically accurate while being performant.
****
![](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/optimized/5X/9/4/d/4/94d46f4e6e3ceb3457cb7d8da22fd021cff66f05_2_690x339.png)

I went for a sort of stylized effect here by multiplying the normals by 10.
****
![](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/optimized/5X/d/6/7/f/d67f1bbb445e65768422721243607a5420639076_2_690x339.png)
![](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/optimized/5X/6/8/8/d/688d6bd585dd4fba1b25eee1e8e2b7aa532aaf7c_2_690x339.png)
****
![](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/5X/c/5/0/a/c50af8cc4f60e562c4ca4fc278b24ee053ac7b86.mp4)
![]([upload://bQKkdGyEcLiZIuUh4oMoCLqegiW.mp4](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/5X/5/3/0/e/530e53c9c8e3a00de5c84dea00e5d2186524dba6.mp4))

This was still a work in progress, where I forgot to invert the foam values.
****
*Most of the images are outdated from one another, the most up to date images are the 2 images at night with foam and the one that blends the caustics with a texture.*

# Want to try it yourself?
Well, fear not, this project is fully open source and available to everyone- do note that **EditableMeshes and EditableImages are still not available on live Roblox servers**, so you will need to open it in Studio to experience it for yourself. You can find the place [here](https://www.roblox.com/games/15133748815/FFT-Ocean).

# Found a mistake or a poorly performing piece of code?
Think you found a mistake or found a way to improve performance? Well, if you did then you can open a pull request to [https://github.com/Icy-Monster/Phillips-Ocean](https://github.com/Icy-Monster/Phillips-Ocean). Any and all contributions are welcome and greatly appreciated.

# References
Tessendorf, Jerry. (2001). "Simulating Ocean Water." In "Simulating Nature: Realistic and Interactive Techniques," *SIGGRAPH 2001* 

Scrawk. (2022). Phillips-Ocean. GitHub. Retrieved from [https://github.com/Scrawk/Phillips-Ocean](https://github.com/Scrawk/Phillips-Ocean)

Finch, M., & Cyan Worlds. (2004). Chapter 1: Effective Water Simulation from Physical Models. In Pharr, M., & Fernando, R. (Eds.), GPU Gems: Programming Techniques, Tips, and Tricks for Real-Time Graphics (pp. 9-29). Addison-Wesley Professional.

Guardado, J., & Sánchez-Crespo, D. (2004). Chapter 2: Rendering Water Caustics. In Pharr, M., & Fernando, R. (Eds.), GPU Gems: Programming Techniques, Tips, and Tricks for Real-Time Graphics (pp. 31-50). Addison-Wesley Professional.

Kryachko, Y., & 1C:Maddox Games. (2005). Chapter 18: Using Vertex Texture Displacement for Realistic Water Rendering. In Pharr, M. (Ed.), GPU Gems 2: Programming Techniques for High-Performance Graphics and General-Purpose Computation (pp. 185-203). Addison-Wesley.
