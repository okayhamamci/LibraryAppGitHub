namespace LibraryApp.Models
{
    public class Book
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Author { get; set; }
        public bool IsAvailable { get; set; }
        public bool IsArchived { get; set; } = false;
        public ICollection<BorrowRecord> BorrowRecords { get; set; }
    }
}
