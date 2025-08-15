"""AST-based code chunking using tree-sitter"""
import logging
import os
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from pathlib import Path
import tree_sitter_languages
import tree_sitter as ts

logger = logging.getLogger(__name__)


@dataclass
class CodeChunk:
    """Represents a chunk of code with metadata"""
    content: str
    file_path: str
    start_line: int
    end_line: int
    language: str
    chunk_type: str  # 'function', 'class', 'method', 'block', 'file'
    function_name: Optional[str] = None
    class_name: Optional[str] = None
    imports: List[str] = None
    context: Optional[str] = None  # surrounding context


class CodeChunker:
    """AST-based code chunking using tree-sitter"""
    
    # Language mappings for tree-sitter
    LANGUAGE_MAPPING = {
        '.py': 'python',
        '.js': 'javascript',
        '.ts': 'typescript',
        '.tsx': 'tsx',
        '.jsx': 'javascript',
        '.java': 'java',
        '.cpp': 'cpp',
        '.c': 'c',
        '.cs': 'c_sharp',
        '.php': 'php',
        '.rb': 'ruby',
        '.go': 'go',
        '.rs': 'rust',
        '.swift': 'swift',
        '.kt': 'kotlin',
        '.scala': 'scala',
        '.r': 'r',
        '.sql': 'sql',
        '.sh': 'bash',
        '.yaml': 'yaml',
        '.yml': 'yaml',
        '.json': 'json',
        '.xml': 'xml',
        '.html': 'html',
        '.css': 'css',
        '.scss': 'css',
        '.sass': 'css',
        '.md': 'markdown',
        '.tex': 'latex',
    }
    
    # Node types that represent meaningful code blocks
    FUNCTION_NODES = {
        'python': ['function_definition', 'async_function_definition'],
        'javascript': ['function_declaration', 'function_expression', 'arrow_function', 'method_definition'],
        'typescript': ['function_declaration', 'function_expression', 'arrow_function', 'method_definition'],
        'tsx': ['function_declaration', 'function_expression', 'arrow_function', 'method_definition'],
        'java': ['method_declaration', 'constructor_declaration'],
        'cpp': ['function_definition', 'method_definition'],
        'c': ['function_definition'],
        'c_sharp': ['method_declaration', 'constructor_declaration'],
        'go': ['function_declaration', 'method_declaration'],
        'rust': ['function_item', 'impl_item'],
        'swift': ['function_declaration'],
    }
    
    CLASS_NODES = {
        'python': ['class_definition'],
        'javascript': ['class_declaration'],
        'typescript': ['class_declaration', 'interface_declaration'],
        'tsx': ['class_declaration', 'interface_declaration'],
        'java': ['class_declaration', 'interface_declaration'],
        'cpp': ['class_specifier'],
        'c_sharp': ['class_declaration', 'interface_declaration'],
        'go': ['type_declaration'],
        'rust': ['struct_item', 'enum_item', 'trait_item'],
        'swift': ['class_declaration', 'struct_declaration', 'protocol_declaration'],
    }
    
    def __init__(self, max_chunk_size: int = 1000, min_chunk_size: int = 50):
        self.max_chunk_size = max_chunk_size
        self.min_chunk_size = min_chunk_size
        self.parsers = {}
        self._initialize_parsers()
    
    def _initialize_parsers(self):
        """Initialize tree-sitter parsers for supported languages"""
        for ext, lang in self.LANGUAGE_MAPPING.items():
            try:
                parser = ts.Parser()
                language = tree_sitter_languages.get_language(lang)
                parser.set_language(language)
                self.parsers[lang] = parser
                logger.debug(f"Initialized parser for {lang}")
            except Exception as e:
                logger.warning(f"Failed to initialize parser for {lang}: {str(e)}")
    
    def get_language_from_file(self, file_path: str) -> Optional[str]:
        """Determine language from file extension"""
        ext = Path(file_path).suffix.lower()
        return self.LANGUAGE_MAPPING.get(ext)
    
    def chunk_file(self, file_path: str, content: str) -> List[CodeChunk]:
        """Chunk a file into semantic code blocks"""
        language = self.get_language_from_file(file_path)
        
        if not language or language not in self.parsers:
            # Fallback to line-based chunking for unsupported languages
            return self._chunk_by_lines(file_path, content, language or 'text')
        
        try:
            return self._chunk_with_ast(file_path, content, language)
        except Exception as e:
            logger.warning(f"AST chunking failed for {file_path}: {str(e)}, falling back to line chunking")
            return self._chunk_by_lines(file_path, content, language)
    
    def _chunk_with_ast(self, file_path: str, content: str, language: str) -> List[CodeChunk]:
        """Chunk code using AST analysis"""
        parser = self.parsers[language]
        tree = parser.parse(content.encode())
        lines = content.split('\n')
        
        chunks = []
        
        # Extract imports first
        imports = self._extract_imports(tree.root_node, content, language)
        
        # Find all function and class definitions
        function_nodes = self._find_nodes_by_type(tree.root_node, self.FUNCTION_NODES.get(language, []))
        class_nodes = self._find_nodes_by_type(tree.root_node, self.CLASS_NODES.get(language, []))
        
        # Process class definitions and their methods
        for class_node in class_nodes:
            class_chunk = self._create_chunk_from_node(
                class_node, file_path, content, language, 'class', imports
            )
            if class_chunk:
                chunks.append(class_chunk)
                
                # Extract methods within the class
                class_functions = self._find_nodes_by_type(class_node, self.FUNCTION_NODES.get(language, []))
                for func_node in class_functions:
                    method_chunk = self._create_chunk_from_node(
                        func_node, file_path, content, language, 'method', imports
                    )
                    if method_chunk:
                        method_chunk.class_name = class_chunk.function_name  # class name stored in function_name
                        chunks.append(method_chunk)
        
        # Process standalone functions (not within classes)
        for func_node in function_nodes:
            # Skip if this function is already processed as part of a class
            if not self._is_within_any_node(func_node, class_nodes):
                func_chunk = self._create_chunk_from_node(
                    func_node, file_path, content, language, 'function', imports
                )
                if func_chunk:
                    chunks.append(func_chunk)
        
        # Handle remaining code (global scope, comments, etc.)
        covered_lines = set()
        for chunk in chunks:
            for line_num in range(chunk.start_line, chunk.end_line + 1):
                covered_lines.add(line_num)
        
        # Create chunks for uncovered significant blocks
        uncovered_chunks = self._chunk_uncovered_lines(
            file_path, lines, covered_lines, language, imports
        )
        chunks.extend(uncovered_chunks)
        
        return chunks
    
    def _find_nodes_by_type(self, node: ts.Node, target_types: List[str]) -> List[ts.Node]:
        """Find all nodes of specified types"""
        result = []
        
        def traverse(n):
            if n.type in target_types:
                result.append(n)
            for child in n.children:
                traverse(child)
        
        traverse(node)
        return result
    
    def _create_chunk_from_node(
        self, 
        node: ts.Node, 
        file_path: str, 
        content: str, 
        language: str, 
        chunk_type: str,
        imports: List[str]
    ) -> Optional[CodeChunk]:
        """Create a code chunk from an AST node"""
        start_line = node.start_point[0] + 1  # Convert to 1-based line numbers
        end_line = node.end_point[0] + 1
        
        # Extract the code content
        lines = content.split('\n')
        chunk_content = '\n'.join(lines[start_line-1:end_line])
        
        # Skip if chunk is too small or large
        if len(chunk_content) < self.min_chunk_size:
            return None
        
        if len(chunk_content) > self.max_chunk_size:
            # Try to split large chunks
            return self._split_large_chunk(node, file_path, content, language, chunk_type, imports)
        
        # Extract function/class name
        name = self._extract_name_from_node(node, content)
        
        return CodeChunk(
            content=chunk_content,
            file_path=file_path,
            start_line=start_line,
            end_line=end_line,
            language=language,
            chunk_type=chunk_type,
            function_name=name,
            imports=imports
        )
    
    def _extract_name_from_node(self, node: ts.Node, content: str) -> Optional[str]:
        """Extract function or class name from AST node"""
        # Look for identifier nodes that represent names
        for child in node.children:
            if child.type == 'identifier':
                return content[child.start_byte:child.end_byte]
        
        # Some languages have different patterns
        name_node = None
        for child in node.children:
            if child.type in ['function_declarator', 'type_identifier', 'property_identifier']:
                # For C/C++ style languages
                for subchild in child.children:
                    if subchild.type == 'identifier':
                        name_node = subchild
                        break
            elif child.type in ['name', 'identifier']:
                name_node = child
                break
        
        if name_node:
            return content[name_node.start_byte:name_node.end_byte]
        
        return None
    
    def _extract_imports(self, root_node: ts.Node, content: str, language: str) -> List[str]:
        """Extract import statements from code"""
        imports = []
        
        import_types = {
            'python': ['import_statement', 'import_from_statement'],
            'javascript': ['import_statement'],
            'typescript': ['import_statement'],
            'tsx': ['import_statement'],
            'java': ['import_declaration'],
            'go': ['import_declaration'],
            'rust': ['use_declaration'],
        }
        
        target_types = import_types.get(language, [])
        if not target_types:
            return imports
        
        import_nodes = self._find_nodes_by_type(root_node, target_types)
        for node in import_nodes:
            import_text = content[node.start_byte:node.end_byte]
            imports.append(import_text.strip())
        
        return imports
    
    def _is_within_any_node(self, target_node: ts.Node, container_nodes: List[ts.Node]) -> bool:
        """Check if target node is within any of the container nodes"""
        for container in container_nodes:
            if (container.start_byte <= target_node.start_byte and 
                target_node.end_byte <= container.end_byte):
                return True
        return False
    
    def _split_large_chunk(
        self, 
        node: ts.Node, 
        file_path: str, 
        content: str, 
        language: str, 
        chunk_type: str,
        imports: List[str]
    ) -> Optional[CodeChunk]:
        """Split large chunks into smaller ones"""
        # For now, just truncate - could be enhanced to split more intelligently
        lines = content.split('\n')
        start_line = node.start_point[0] + 1
        
        # Calculate how many lines fit in max_chunk_size
        chars_per_line = self.max_chunk_size // 20  # rough estimate
        max_lines = max(10, chars_per_line)  # at least 10 lines
        
        end_line = min(node.end_point[0] + 1, start_line + max_lines - 1)
        chunk_content = '\n'.join(lines[start_line-1:end_line])
        
        name = self._extract_name_from_node(node, content)
        
        return CodeChunk(
            content=chunk_content + '\n# ... (truncated)',
            file_path=file_path,
            start_line=start_line,
            end_line=end_line,
            language=language,
            chunk_type=chunk_type + '_partial',
            function_name=name,
            imports=imports
        )
    
    def _chunk_uncovered_lines(
        self, 
        file_path: str, 
        lines: List[str], 
        covered_lines: set, 
        language: str,
        imports: List[str]
    ) -> List[CodeChunk]:
        """Create chunks for lines not covered by functions/classes"""
        chunks = []
        current_chunk_lines = []
        current_start_line = None
        
        for i, line in enumerate(lines, 1):
            if i not in covered_lines and line.strip():  # Skip empty lines
                if current_start_line is None:
                    current_start_line = i
                current_chunk_lines.append(line)
                
                # Check if chunk is getting too large
                chunk_content = '\n'.join(current_chunk_lines)
                if len(chunk_content) >= self.max_chunk_size:
                    # Create chunk
                    if len(chunk_content) >= self.min_chunk_size:
                        chunks.append(CodeChunk(
                            content=chunk_content,
                            file_path=file_path,
                            start_line=current_start_line,
                            end_line=i,
                            language=language,
                            chunk_type='block',
                            imports=imports
                        ))
                    
                    current_chunk_lines = []
                    current_start_line = None
            else:
                # Gap in coverage, finalize current chunk if any
                if current_chunk_lines:
                    chunk_content = '\n'.join(current_chunk_lines)
                    if len(chunk_content) >= self.min_chunk_size:
                        chunks.append(CodeChunk(
                            content=chunk_content,
                            file_path=file_path,
                            start_line=current_start_line,
                            end_line=i-1,
                            language=language,
                            chunk_type='block',
                            imports=imports
                        ))
                    
                    current_chunk_lines = []
                    current_start_line = None
        
        # Handle final chunk
        if current_chunk_lines:
            chunk_content = '\n'.join(current_chunk_lines)
            if len(chunk_content) >= self.min_chunk_size:
                chunks.append(CodeChunk(
                    content=chunk_content,
                    file_path=file_path,
                    start_line=current_start_line,
                    end_line=len(lines),
                    language=language,
                    chunk_type='block',
                    imports=imports
                ))
        
        return chunks
    
    def _chunk_by_lines(self, file_path: str, content: str, language: str) -> List[CodeChunk]:
        """Fallback line-based chunking for unsupported languages"""
        lines = content.split('\n')
        chunks = []
        
        current_chunk_lines = []
        current_start_line = 1
        
        for i, line in enumerate(lines, 1):
            current_chunk_lines.append(line)
            chunk_content = '\n'.join(current_chunk_lines)
            
            if len(chunk_content) >= self.max_chunk_size:
                if len(chunk_content) >= self.min_chunk_size:
                    chunks.append(CodeChunk(
                        content=chunk_content,
                        file_path=file_path,
                        start_line=current_start_line,
                        end_line=i,
                        language=language,
                        chunk_type='file'
                    ))
                
                current_chunk_lines = []
                current_start_line = i + 1
        
        # Handle final chunk
        if current_chunk_lines:
            chunk_content = '\n'.join(current_chunk_lines)
            if len(chunk_content) >= self.min_chunk_size:
                chunks.append(CodeChunk(
                    content=chunk_content,
                    file_path=file_path,
                    start_line=current_start_line,
                    end_line=len(lines),
                    language=language,
                    chunk_type='file'
                ))
        
        return chunks