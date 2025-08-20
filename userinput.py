def main():
    print("🚀 10x-Tool-Calls Loop Started")
    print("Type your next instruction below. Type 'exit' to quit.\n")

    while True:
        user_input = input(">>> Your next instruction: ").strip()

        if user_input.lower() in ["exit", "quit", "q"]:
            print("👋 Exiting 10x-Tool-Calls loop.")
            break

        # هنا بيرجع الـ prompt علشان ال-Agent يكمل عليه
        print(f"[10x-Tool-Calls] Next Prompt: {user_input}")

if __name__ == "__main__":
    main()
