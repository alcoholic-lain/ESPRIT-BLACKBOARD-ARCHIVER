"""
Blackboard API Scraper for ESPRIT
Based on TimEnglart/BlackBoard-Course-Downloader
"""

import os
import re
import sys
import json
import requests
import html as html_lib
import xmltodict
from pathlib import Path
from getpass import getpass
from urllib.parse import unquote
from concurrent.futures import ThreadPoolExecutor, as_completed

SITE = "https://esprit.blackboard.com"
DOWNLOAD_DIR = Path(__file__).parent / "downloads"

def sanitize(name):
    if not name:
        return "unnamed"
    name = re.sub(r'[<>:"/\\|?*]', '_', str(name))
    return name[:100].strip()


class BlackboardAPI:
    def __init__(self, username, password):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0'
        })
        self.site = SITE
        self.username = username
        self.password = password
        self.user_id = None
        self.stats = {"files": 0, "pages": 0, "errors": 0}
    
    def login(self):
        print("🔐 Logging in...")
        
        r = self.session.post(
            f"{self.site}/webapps/Bb-mobile-bb_bb60/sslUserLogin",
            data={'username': self.username, 'password': self.password}
        )
        
        if r.status_code == 200:
            try:
                response = xmltodict.parse(r.text)['mobileresponse']
                if response.get('@status') == 'OK':
                    self.user_id = response.get('@userid')
                    print(f"✅ Logged in: {self.user_id}")
                    return True
            except:
                pass
        print("❌ Login failed")
        return False
    
    def api_get(self, endpoint, silent=False):
        url = self.site + endpoint if endpoint.startswith('/') else endpoint
        try:
            r = self.session.get(url)
            if r.status_code == 200:
                return r.json()
            elif r.status_code == 401:
                self.login()
                r = self.session.get(url)
                if r.status_code == 200:
                    return r.json()
        except:
            pass
        if not silent:
            self.stats["errors"] += 1
        return None
    
    def get_courses(self):
        print("📚 Fetching courses...")
        
        data = self.api_get(f"/learn/api/public/v1/users/{self.user_id}/courses?limit=100")
        
        if not data or "results" not in data:
            return self.get_courses_mobile()
        
        courses = []
        for item in data.get("results", []):
            course_id = item.get("courseId")
            course_data = self.api_get(f"/learn/api/public/v1/courses/{course_id}", silent=True)
            if course_data:
                courses.append({
                    "id": course_id,
                    "name": course_data.get("name", "Unknown")
                })
        
        print(f"✅ Found {len(courses)} courses")
        return courses
    
    def get_courses_mobile(self):
        r = self.session.get(f"{self.site}/webapps/Bb-mobile-bb_bb60/enrollments?course_type=ALL")
        try:
            data = xmltodict.parse(r.text)
            courses_data = data.get('mobileresponse', {}).get('courses', {}).get('course', [])
            if not isinstance(courses_data, list):
                courses_data = [courses_data] if courses_data else []
            return [{"id": c.get('@bbid'), "name": c.get('@name', 'Unknown')} for c in courses_data]
        except:
            return []
    
    def get_contents(self, course_id, parent_id=None):
        if parent_id:
            endpoint = f"/learn/api/public/v1/courses/{course_id}/contents/{parent_id}/children"
        else:
            endpoint = f"/learn/api/public/v1/courses/{course_id}/contents"
        
        all_results = []
        while endpoint:
            data = self.api_get(endpoint, silent=True)
            if not data:
                break
            all_results.extend(data.get("results", []))
            endpoint = data.get("paging", {}).get("nextPage")
        
        return all_results
    
    def get_attachments(self, course_id, content_id):
        data = self.api_get(f"/learn/api/public/v1/courses/{course_id}/contents/{content_id}/attachments", silent=True)
        return data.get("results", []) if data else []
    
    def download_file(self, url, filepath):
        if url.startswith("/"):
            url = self.site + url
        
        try:
            r = self.session.get(url, stream=True, allow_redirects=True, timeout=60)
            
            if r.status_code == 200:
                filepath.parent.mkdir(parents=True, exist_ok=True)
                
                if filepath.exists():
                    return False
                
                with open(filepath, 'wb') as f:
                    for chunk in r.iter_content(8192):
                        f.write(chunk)
                
                print(f"    ✓ {filepath.name}")
                self.stats["files"] += 1
                return True
        except Exception as e:
            self.stats["errors"] += 1
        return False
    
    def extract_files_from_body(self, body):
        if not body:
            return []
        
        files = []
        
        # data-bbfile pattern (embedded files)
        pattern = r'data-bbfile="({[^"]+})"'
        for match in re.findall(pattern, str(body)):
            try:
                decoded = html_lib.unescape(match)
                file_data = json.loads(decoded)
                filename = file_data.get('fileName') or file_data.get('linkName')
                if filename:
                    href_pattern = rf'data-bbfile="{re.escape(match)}"[^>]*href="([^"]+)"'
                    href_match = re.search(href_pattern, str(body))
                    if href_match:
                        files.append({'url': html_lib.unescape(href_match.group(1)), 'filename': filename})
            except:
                pass
        
        # Direct file links
        extensions = ['.pdf', '.docx', '.doc', '.pptx', '.ppt', '.xlsx', '.xls', '.sql', '.zip', '.rar', '.txt', '.py', '.java', '.c']
        for ext in extensions:
            pattern = rf'href="([^"]*{re.escape(ext)})"'
            for url in re.findall(pattern, str(body), re.IGNORECASE):
                url = html_lib.unescape(url)
                filename = unquote(url.split('/')[-1].split('?')[0])
                if filename and not any(f['filename'] == filename for f in files):
                    files.append({'url': url, 'filename': filename})
        
        # IMAGES - extract all img src
        img_pattern = r'<img[^>]+src="([^"]+)"'
        for url in re.findall(img_pattern, str(body), re.IGNORECASE):
            url = html_lib.unescape(url)
            filename = unquote(url.split('/')[-1].split('?')[0])
            if filename and not any(f['filename'] == filename for f in files):
                files.append({'url': url, 'filename': filename, 'is_image': True})
        
        return files
    
    def download_images_and_fix_html(self, body, save_path):
        """Download images and embed as base64 in HTML for offline viewing"""
        if not body:
            return body
        
        import base64
        import mimetypes
        
        # 1. Handle regular <img> tags
        img_pattern = r'<img[^>]+src="([^"]+)"'
        
        for url in re.findall(img_pattern, str(body), re.IGNORECASE):
            original_url = url
            url = html_lib.unescape(url)
            
            # Skip data URIs (already embedded)
            if url.startswith('data:'):
                continue
            
            # Handle Blackboard's @X@ style paths
            if '@X@' in url:
                url = url.replace('@X@EmbeddedFile', '/bbcswebdav')
                url = url.replace('@', '/')
            
            filename = unquote(url.split('/')[-1].split('?')[0])
            
            if not filename:
                filename = f"image_{hash(url) % 10000}"
            
            # Build full URL
            if url.startswith('/'):
                full_url = self.site + url
            elif not url.startswith('http'):
                full_url = self.site + '/' + url
            else:
                full_url = url
            
            # Try to download and embed as base64
            try:
                r = self.session.get(full_url, timeout=30)
                if r.status_code == 200:
                    content_type = r.headers.get('Content-Type', 'image/png')
                    if 'image' in content_type or filename.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.svg')):
                        if 'image' not in content_type:
                            mime_type, _ = mimetypes.guess_type(filename)
                            content_type = mime_type or 'image/png'
                        
                        b64_data = base64.b64encode(r.content).decode('utf-8')
                        data_uri = f'data:{content_type};base64,{b64_data}'
                        body = body.replace(f'src="{original_url}"', f'src="{data_uri}"')
                        print(f"    🖼️ Embedded img: {filename}")
                        self.stats["files"] += 1
            except Exception as e:
                print(f"    ⚠️ Image failed: {filename} - {e}")
        
        # 2. Handle Blackboard's <a data-bbfile> attachment links that should be images
        # Pattern: <a href="..." data-bbfile="{...mimeType...image/jpeg...}">filename</a>
        bbfile_pattern = r'<a\s+href="([^"]+)"[^>]*data-bbtype="attachment"[^>]*data-bbfile="([^"]+)"[^>]*>([^<]+)</a>'
        
        for match in re.finditer(bbfile_pattern, str(body), re.IGNORECASE):
            full_match = match.group(0)
            href = html_lib.unescape(match.group(1))
            bbfile_data = html_lib.unescape(match.group(2))
            link_text = match.group(3)
            
            # Check if this is an image based on mimeType in data-bbfile
            is_image = False
            try:
                file_info = json.loads(bbfile_data)
                mime_type = file_info.get('mimeType', '')
                is_image = 'image' in mime_type.lower()
                filename = file_info.get('fileName', link_text)
            except:
                # Fallback: check if link text looks like an image filename
                is_image = link_text.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'))
                filename = link_text
                mime_type = 'image/jpeg'
            
            if is_image:
                # Download the image
                if href.startswith('/'):
                    full_url = self.site + href
                elif not href.startswith('http'):
                    full_url = self.site + '/' + href
                else:
                    full_url = href
                
                try:
                    r = self.session.get(full_url, timeout=30)
                    if r.status_code == 200:
                        # Get content type from response or use the one from data-bbfile
                        content_type = r.headers.get('Content-Type', mime_type)
                        if 'image' not in content_type:
                            content_type = mime_type or 'image/jpeg'
                        
                        b64_data = base64.b64encode(r.content).decode('utf-8')
                        data_uri = f'data:{content_type};base64,{b64_data}'
                        
                        # Replace <a> tag with <img> tag
                        img_tag = f'<img src="{data_uri}" alt="{html_lib.escape(filename)}" style="max-width:100%">'
                        body = body.replace(full_match, img_tag)
                        print(f"    🖼️ Converted to img: {filename}")
                        self.stats["files"] += 1
                except Exception as e:
                    print(f"    ⚠️ Image conversion failed: {filename} - {e}")
        
        return body
    
    def save_page_content(self, title, body, filepath):
        if not body or not body.strip():
            return False
        
        html_content = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>{html_lib.escape(title)}</title>
<style>body{{font-family:Arial,sans-serif;margin:40px;line-height:1.6}}img{{max-width:100%}}</style>
</head><body>{body}</body></html>"""
        
        html_path = filepath.with_suffix('.html')
        if html_path.exists():
            return False
        
        html_path.parent.mkdir(parents=True, exist_ok=True)
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"    📄 {html_path.name}")
        self.stats["pages"] += 1
        return True
    
    def process_content(self, course_id, content, save_path, level=0):
        indent = "  " * level
        title = content.get('title', 'Untitled')
        content_id = content.get('id')
        has_children = content.get('hasChildren', False)
        body = content.get('body')
        handler = content.get('contentHandler', {})
        handler_id = handler.get('id', '')
        
        # Determine item type
        is_folder = handler_id in ['resource/x-bb-folder', 'resource/x-bb-lesson']
        is_module = 'learning-module' in handler_id.lower() if handler_id else False
        
        icon = "📁" if (has_children or is_folder or is_module) else "📄"
        print(f"{indent}{icon} {title}")
        
        # Set path for this item
        if has_children or is_folder or is_module:
            item_path = save_path / sanitize(title)
        else:
            item_path = save_path
        
        # 1. Download API attachments
        attachments = self.get_attachments(course_id, content_id)
        for att in attachments:
            att_id = att.get('id')
            filename = att.get('fileName', f'file_{att_id}')
            url = f"/learn/api/public/v1/courses/{course_id}/contents/{content_id}/attachments/{att_id}/download"
            self.download_file(url, item_path / sanitize(filename))
        
        # 2. Check contentHandler for embedded file
        if handler.get('file'):
            file_info = handler['file']
            filename = file_info.get('fileName')
            if filename:
                url = f"/learn/api/public/v1/courses/{course_id}/contents/{content_id}/attachments"
                self.download_file(url, item_path / sanitize(filename))
        
        # 3. Extract files from body HTML (including images)
        for file_info in self.extract_files_from_body(body):
            file_url = file_info['url']
            if file_url.startswith('/'):
                file_url = self.site + file_url
            elif not file_url.startswith('http'):
                file_url = self.site + '/' + file_url
            self.download_file(file_url, item_path / sanitize(file_info['filename']))
        
        # 4. Save page content as HTML with images downloaded
        if body and handler_id == 'resource/x-bb-document':
            item_path.mkdir(parents=True, exist_ok=True)
            fixed_body = self.download_images_and_fix_html(body, item_path)
            self.save_page_content(title, fixed_body, item_path / sanitize(title))
        
        # 5. RECURSIVELY process children
        if has_children:
            children = self.get_contents(course_id, content_id)
            for child in children:
                self.process_content(course_id, child, item_path, level + 1)
    
    def download_course(self, course, save_dir):
        print(f"\n{'='*60}")
        print(f"📚 {course['name']}")
        print(f"{'='*60}")
        
        self.stats = {"files": 0, "pages": 0, "errors": 0}
        course_dir = save_dir / sanitize(course['name'])
        course_dir.mkdir(parents=True, exist_ok=True)
        
        # Get top-level contents
        contents = self.get_contents(course['id'])
        
        if not contents:
            print("  ⚠ No content accessible via API")
            return self.stats
        
        # Process each top-level item
        for content in contents:
            self.process_content(course['id'], content, course_dir)
        
        print(f"\n✅ Done: {self.stats['files']} files, {self.stats['pages']} pages")
        if self.stats['errors'] > 0:
            print(f"   ⚠ {self.stats['errors']} errors")
        
        return self.stats


def main():
    print("="*60)
    print("🎓 Blackboard API Scraper")
    print("="*60)
    
    username = input("Username: ").strip()
    password = getpass("Password: ")
    
    if not username or not password:
        print("❌ Credentials required!")
        return
    
    api = BlackboardAPI(username, password)
    
    if not api.login():
        return
    
    courses = api.get_courses()
    
    if not courses:
        print("❌ No courses found")
        return
    
    print("\nCourses:")
    for i, course in enumerate(courses, 1):
        print(f"  [{i}] {course['name']}")
    
    print("\n  [a] Download ALL")
    print("  [q] Quit")
    
    choice = input("\nChoice: ").strip().lower()
    
    if choice == 'q':
        return
    
    DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
    
    total_stats = {"files": 0, "pages": 0}
    
    if choice == 'a':
        for course in courses:
            stats = api.download_course(course, DOWNLOAD_DIR)
            total_stats["files"] += stats["files"]
            total_stats["pages"] += stats["pages"]
        print(f"\n{'='*60}")
        print(f"📊 TOTAL: {total_stats['files']} files, {total_stats['pages']} pages")
    else:
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(courses):
                api.download_course(courses[idx], DOWNLOAD_DIR)
        except ValueError:
            print("❌ Invalid input")
    
    print(f"\n📁 Saved to: {DOWNLOAD_DIR.absolute()}")


if __name__ == "__main__":
    main()
