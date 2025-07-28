package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/ignorer/ignorer/internal/core"
	"github.com/spf13/cobra"
)

// Version is set at build time via ldflags
var version = "dev"

var rootCmd = &cobra.Command{
	Use:   "ignorer [templates...]",
	Short: "🚫 Generate .gitignore files from predefined templates",
	Long: `🚫 Ignorer - Smart .gitignore Generator

Ignorer is a CLI tool that generates .gitignore files by combining 
predefined templates for different programming languages and frameworks.

✨ Examples:
  🍎 ignorer swift xcode      # Create .gitignore for Swift and Xcode
  🐹 ignorer go docker        # Create .gitignore for Go and Docker  
  ⚛️  ignorer react node       # Create .gitignore for React and Node
  📋 ignorer list            # List all available templates

🔗 More info: https://github.com/ignorer/ignorer`,
	Args: cobra.ArbitraryArgs,
	RunE: generateGitignore,
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "📋 List all available templates",
	Long:  "📋 Display all available .gitignore templates for different languages and frameworks",
	RunE:  listTemplates,
}

func init() {
	rootCmd.AddCommand(listCmd)

	// Add version flag
	rootCmd.Flags().BoolP("version", "v", false, "Show version information")
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func generateGitignore(cmd *cobra.Command, args []string) error {
	// Handle version flag
	if versionFlag, _ := cmd.Flags().GetBool("version"); versionFlag {
		fmt.Printf("🚫 v%s\n", version)
		return nil
	}

	// If no arguments provided and no version flag, show help
	if len(args) == 0 {
		return cmd.Help()
	}

	if len(args) == 1 && args[0] == "list" {
		return listTemplates(cmd, args)
	}

	templateManager := core.NewTemplateManager()

	// Load available templates
	if err := templateManager.LoadTemplates(); err != nil {
		return fmt.Errorf("failed to load templates: %w", err)
	}

	// Generate combined gitignore content
	content, err := templateManager.GenerateGitignore(args)
	if err != nil {
		return err
	}

	// Write to .gitignore file
	gitignorePath := filepath.Join(".", ".gitignore")
	if err := os.WriteFile(gitignorePath, []byte(content), 0644); err != nil {
		return fmt.Errorf("failed to write .gitignore file: %w", err)
	}

	fmt.Printf("✅ Generated .gitignore with templates: %s\n", strings.Join(args, ", "))
	return nil
}

func listTemplates(cmd *cobra.Command, args []string) error {
	templateManager := core.NewTemplateManager()

	if err := templateManager.LoadTemplates(); err != nil {
		return fmt.Errorf("failed to load templates: %w", err)
	}

	templates := templateManager.ListTemplates()

	fmt.Println("📋 Available .gitignore templates:")
	fmt.Println()

	// Group templates by category for better display
	languages := make([]string, 0)
	frameworks := make([]string, 0)
	tools := make([]string, 0)

	for _, template := range templates {
		switch {
		case isLanguage(template):
			languages = append(languages, template)
		case isFramework(template):
			frameworks = append(frameworks, template)
		default:
			tools = append(tools, template)
		}
	}

	if len(languages) > 0 {
		fmt.Println("🔤 Languages:")
		for _, lang := range languages {
			fmt.Printf("  - %s\n", lang)
		}
		fmt.Println()
	}

	if len(frameworks) > 0 {
		fmt.Println("🚀 Frameworks:")
		for _, framework := range frameworks {
			fmt.Printf("  - %s\n", framework)
		}
		fmt.Println()
	}

	if len(tools) > 0 {
		fmt.Println("🛠️  Tools & Others:")
		for _, tool := range tools {
			fmt.Printf("  - %s\n", tool)
		}
		fmt.Println()
	}

	fmt.Printf("💡 Usage: ignorer <template1> [template2] [...]\n")
	fmt.Printf("   Example: ignorer %s\n", getExampleUsage(templates))

	return nil
}

func isLanguage(template string) bool {
	languages := []string{"swift", "go", "python", "java", "javascript", "typescript", "rust", "cpp", "c", "php", "ruby", "kotlin", "scala"}
	for _, lang := range languages {
		if strings.EqualFold(template, lang) {
			return true
		}
	}
	return false
}

func isFramework(template string) bool {
	frameworks := []string{"react", "vue", "angular", "django", "flask", "spring", "rails", "laravel", "next", "nest", "reactnative"}
	for _, framework := range frameworks {
		if strings.EqualFold(template, framework) {
			return true
		}
	}
	return false
}

func getExampleUsage(templates []string) string {
	if len(templates) >= 2 {
		return fmt.Sprintf("%s %s", templates[0], templates[1])
	} else if len(templates) >= 1 {
		return templates[0]
	}
	return "swift xcode"
}
