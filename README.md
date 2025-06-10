# 🚀 AI Dev Tasks for Cursor 🤖

Welcome to **AI Dev Tasks**! This repository provides a collection of `.mdc` (Markdown Command) files designed to supercharge your feature development workflow within the [Cursor](https://cursor.sh/) editor. By leveraging these commands with Cursor's AI Agent, you can systematically approach building features, from ideation to implementation, with built-in checkpoints for verification.

## 📦 Repository Contents

This repository contains both the **AI Development Workflow Tools** and a **Complete Civilization VI Mod** as a practical example:

### 🛠️ Development Tools (.mdc files)
- **`create-prd.mdc`**: Guides the AI in generating a Product Requirement Document for your feature.
- **`generate-tasks-from-prd.mdc`**: Takes a PRD markdown file as input and helps the AI break it down into a detailed, step-by-step implementation task list.
- **`process-task-list.mdc`**: Instructs the AI on how to process the generated task list, tackling one task at a time and waiting for your approval before proceeding.

### 🎮 Example Implementation: Detailed Adjacency Preview Mod
- **`DetailedAdjacencyPreview/`**: Complete, deployable Civilization VI mod (copy this folder to your Civ VI mods directory)
- **`tasks/`**: Task breakdown and PRD used to develop the mod
- **Development files**: Scripts, documentation, and implementation history

## 🎯 The Detailed Adjacency Preview Mod

This repository showcases a complete mod for Civilization VI that was built using the AI development workflow. The mod enhances district placement by showing adjacency benefits that existing districts would receive from new placements.

### 🚀 Quick Installation
1. Copy the `DetailedAdjacencyPreview/` folder to your Civilization VI mods directory:
   - **Windows**: `Documents\My Games\Sid Meier's Civilization VI\Mods\`
   - **Mac**: `~/Documents/Sid Meier's Civilization VI/Mods/`
   - **Linux**: `~/.local/share/aspyr-media/Sid Meier's Civilization VI/Mods/`
2. Enable the mod in Civilization VI's Additional Content menu
3. Enjoy enhanced strategic city planning!

## ✨ The Core AI Development Idea

Building complex features with AI can sometimes feel like a black box. This workflow aims to bring structure, clarity, and control to the process by:

1.  **Defining Scope:** Clearly outlining what needs to be built with a Product Requirement Document (PRD).
2.  **Detailed Planning:** Breaking down the PRD into a granular, actionable task list.
3.  **Iterative Implementation:** Guiding the AI to tackle one task at a time, allowing you to review and approve each change.

This structured approach helps ensure the AI stays on track, makes it easier to debug issues, and gives you confidence in the generated code.

## Workflow: From Idea to Implemented Feature 💡➡️💻

Here's the step-by-step process using the `.mdc` files in this repository:

### 1️⃣ Create a Product Requirement Document (PRD)

First, lay out the blueprint for your feature. A PRD clarifies what you're building, for whom, and why.

You can create a lightweight PRD directly within Cursor:

1.  Ensure you have the `create-prd.mdc` file from this repository accessible.
2.  In Cursor's Agent chat, initiate PRD creation:

    ```
    Use @create-prd.mdc
    Here's the feature I want to build: [Describe your feature in detail]
    Reference these files to help you: [Optional: @file1.py @file2.ts]
    ```
    *(Pro Tip: For complex PRDs, using MAX mode in Cursor is highly recommended if your budget allows for more comprehensive generation.)*

### 2️⃣ Generate Your Task List from the PRD

With your PRD drafted (e.g., `MyFeature-PRD.md`), the next step is to generate a detailed, step-by-step implementation plan for your AI Developer.

1.  Ensure you have `generate-tasks-from-prd.mdc` accessible.
2.  In Cursor's Agent chat, use the PRD to create tasks:

    ```
    Now take @MyFeature-PRD.md and create tasks using @generate-tasks-from-prd.mdc
    ```

### 3️⃣ Examine Your Task List

You'll now have a well-structured task list, often with tasks and sub-tasks, ready for the AI to start working on. This provides a clear roadmap for implementation.

### 4️⃣ Instruct the AI to Work Through Tasks (and Mark Completion)

To ensure methodical progress and allow for verification, we'll use `process-task-list.mdc`. This command instructs the AI to focus on one task at a time and wait for your go-ahead before moving to the next.

1.  Create or ensure you have the `process-task-list.mdc` file accessible.
2.  In Cursor's Agent chat, tell the AI to start with the first task (e.g., `1.1`):

    ```
    Please start on task 1.1 and use @process-task-list.mdc
    ```

### 5️⃣ Review, Approve, and Progress ✅

As the AI completes each task, you review the changes.
*   If the changes are good, simply reply with "yes" (or a similar affirmative) to instruct the AI to mark the task complete and move to the next one.
*   If changes are needed, provide feedback to the AI to correct the current task before moving on.

## 📁 Repository Structure

```
├── DetailedAdjacencyPreview/          # 🎮 Deployable Civ VI mod folder
│   ├── DetailedAdjacencyPreview.modinfo
│   ├── Scripts/
│   ├── UI/
│   └── README.md
├── tasks/                             # 📋 Development task breakdown
│   ├── prd-detailed-adjacency-preview.md
│   └── tasks-prd-detailed-adjacency-preview.md
├── Scripts/                           # 💻 Original development files
├── UI/                                # 🎨 Original UI development files
├── create-prd.mdc                     # 🛠️ AI development tools
├── generate-tasks.mdc
├── process-task-list.mdc
├── README.md                          # 📖 This file
└── LICENSE
```

## 🌟 Benefits

*   **Structured Development:** Enforces a clear process from idea to code.
*   **Step-by-Step Verification:** Allows you to review and approve AI-generated code at each small step, ensuring quality and control.
*   **Manages Complexity:** Breaks down large features into smaller, digestible tasks for the AI, reducing the chance of it getting lost or generating overly complex, incorrect code.
*   **Improved Reliability:** Offers a more dependable approach to leveraging AI for significant development work compared to single, large prompts.
*   **Clear Progress Tracking:** Provides a visual representation of completed tasks, making it easy to see how much has been done and what's next.
*   **Real-World Example:** Includes a complete, working mod that demonstrates the entire workflow in action.

## 🛠️ How to Use

1.  **Clone or Download:** Get these `.mdc` files into your project or a central location where Cursor can access them.
2.  **Follow the Workflow:** Systematically use the `.mdc` files in Cursor's Agent chat as described in the 5-step workflow above.
3.  **Study the Example:** Examine how the Detailed Adjacency Preview mod was built using this workflow.
4.  **Adapt and Iterate:**
    *   Feel free to modify the prompts within the `.mdc` files to better suit your specific needs or coding style.
    *   If the AI struggles with a task, try rephrasing your initial feature description or breaking down tasks even further.

## 💡 Tips for Success

*   **Be Specific:** The more context and clear instructions you provide (both in your initial feature description and any clarifications), the better the AI's output will be.
*   **MAX Mode for PRDs:** Using MAX mode in Cursor for PRD creation (`create-prd.mdc`) can yield more thorough and higher-quality results if your budget supports it.
*   **Correct File Tagging:** Always ensure you're accurately tagging the PRD filename (e.g., `@MyFeature-PRD.md`) when generating tasks.
*   **Patience and Iteration:** AI is a powerful tool, but it's not magic. Be prepared to guide, correct, and iterate. This workflow is designed to make that iteration process smoother.

## 🎥 Video Demonstration

If you'd like to see this in action, it was demonstrated on [Claire Vo's "How I AI" podcast](https://www.youtube.com/watch?v=fD4ktSkNCw4).

## 🤝 Contributing

Got ideas to improve these `.mdc` files or have new ones that fit this workflow? Contributions are welcome!
Please feel free to:
*   Open an issue to discuss changes or suggest new features.
*   Submit a pull request with your enhancements.

---

**Happy AI-assisted developing!** 🚀

*Stop wrestling with monolithic AI requests and start guiding your AI collaborator step-by-step!*
