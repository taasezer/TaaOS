/*
 * TaaOS Kernel Module - Core Implementation
 * Provides /proc interface and system hooks
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/sched.h>
#include <linux/taaos.h>
#include <linux/taaos_sched.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Taha Sezer <taha@taaos.local>");
MODULE_DESCRIPTION("TaaOS Kernel Integration Module");
MODULE_VERSION(TAAOS_VERSION);

static struct proc_dir_entry *taaos_proc_dir;
static atomic_t ai_process_count = ATOMIC_INIT(0);
static atomic_t neural_engine_active = ATOMIC_INIT(0);

/* /proc/taaos/info */
static int taaos_info_show(struct seq_file *m, void *v)
{
    seq_printf(m, "TaaOS Kernel Module\n");
    seq_printf(m, "===================\n\n");
    seq_printf(m, "Version: %s\n", TAAOS_VERSION);
    seq_printf(m, "Codename: %s\n", TAAOS_CODENAME);
    seq_printf(m, "Author: %s\n", TAAOS_AUTHOR);
    seq_printf(m, "Build: %s %s\n\n", __DATE__, __TIME__);
    
    seq_printf(m, "Features:\n");
    seq_printf(m, "  Neural Engine: %s\n", 
               IS_ENABLED(CONFIG_TAAOS_NEURAL_ENGINE) ? "Enabled" : "Disabled");
    seq_printf(m, "  AI Boost: %s\n",
               IS_ENABLED(CONFIG_TAAOS_AI_BOOST) ? "Enabled" : "Disabled");
    seq_printf(m, "  Optimizations: %s\n\n",
               IS_ENABLED(CONFIG_TAAOS_OPTIMIZATIONS) ? "Enabled" : "Disabled");
    
    seq_printf(m, "Runtime Stats:\n");
    seq_printf(m, "  AI Processes: %d\n", atomic_read(&ai_process_count));
    seq_printf(m, "  Neural Engine: %s\n",
               atomic_read(&neural_engine_active) ? "Active" : "Inactive");
    
    return 0;
}

/* /proc/taaos/stats */
static int taaos_stats_show(struct seq_file *m, void *v)
{
    struct task_struct *task;
    int ai_count = 0;
    
    seq_printf(m, "TaaOS Process Statistics\n");
    seq_printf(m, "========================\n\n");
    
    rcu_read_lock();
    for_each_process(task) {
        if (strstr(task->comm, "taaos") ||
            strstr(task->comm, "ollama") ||
            strstr(task->comm, "python")) {
            ai_count++;
            seq_printf(m, "PID: %d, Comm: %s, Nice: %d\n",
                      task->pid, task->comm, task_nice(task));
        }
    }
    rcu_read_unlock();
    
    seq_printf(m, "\nTotal AI-related processes: %d\n", ai_count);
    atomic_set(&ai_process_count, ai_count);
    
    return 0;
}

static int taaos_info_open(struct inode *inode, struct file *file)
{
    return single_open(file, taaos_info_show, NULL);
}

static int taaos_stats_open(struct inode *inode, struct file *file)
{
    return single_open(file, taaos_stats_show, NULL);
}

static const struct proc_ops taaos_info_ops = {
    .proc_open = taaos_info_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};

static const struct proc_ops taaos_stats_ops = {
    .proc_open = taaos_stats_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};

/* Neural Engine activation */
int taaos_neural_engine_init(void)
{
    atomic_set(&neural_engine_active, 1);
    pr_info("TaaOS: Neural Engine activated\n");
    return 0;
}
EXPORT_SYMBOL(taaos_neural_engine_init);

void taaos_neural_engine_exit(void)
{
    atomic_set(&neural_engine_active, 0);
    pr_info("TaaOS: Neural Engine deactivated\n");
}
EXPORT_SYMBOL(taaos_neural_engine_exit);

static int __init taaos_init(void)
{
    pr_info("TaaOS: Initializing kernel integration module\n");
    pr_info("TaaOS: Version %s (%s)\n", TAAOS_VERSION, TAAOS_CODENAME);
    
    /* Create /proc/taaos directory */
    taaos_proc_dir = proc_mkdir(TAAOS_PROC_DIR, NULL);
    if (!taaos_proc_dir) {
        pr_err("TaaOS: Failed to create /proc/%s\n", TAAOS_PROC_DIR);
        return -ENOMEM;
    }
    
    /* Create /proc/taaos/info */
    if (!proc_create(TAAOS_PROC_INFO, 0444, taaos_proc_dir, &taaos_info_ops)) {
        pr_err("TaaOS: Failed to create /proc/%s/%s\n", 
               TAAOS_PROC_DIR, TAAOS_PROC_INFO);
        remove_proc_entry(TAAOS_PROC_DIR, NULL);
        return -ENOMEM;
    }
    
    /* Create /proc/taaos/stats */
    if (!proc_create(TAAOS_PROC_STATS, 0444, taaos_proc_dir, &taaos_stats_ops)) {
        pr_err("TaaOS: Failed to create /proc/%s/%s\n",
               TAAOS_PROC_DIR, TAAOS_PROC_STATS);
        remove_proc_entry(TAAOS_PROC_INFO, taaos_proc_dir);
        remove_proc_entry(TAAOS_PROC_DIR, NULL);
        return -ENOMEM;
    }
    
    pr_info("TaaOS: Kernel integration complete\n");
    pr_info("TaaOS: /proc/%s interface ready\n", TAAOS_PROC_DIR);
    
    return 0;
}

static void __exit taaos_exit(void)
{
    remove_proc_entry(TAAOS_PROC_STATS, taaos_proc_dir);
    remove_proc_entry(TAAOS_PROC_INFO, taaos_proc_dir);
    remove_proc_entry(TAAOS_PROC_DIR, NULL);
    
    pr_info("TaaOS: Kernel integration module removed\n");
}

module_init(taaos_init);
module_exit(taaos_exit);
